import 'dart:async';

import 'package:collection/collection.dart';
import 'package:fl_query/src/collections/default_configs.dart';
import 'package:fl_query/src/collections/json_config.dart';
import 'package:fl_query/src/collections/refresh_config.dart';
import 'package:fl_query/src/collections/retry_config.dart';
import 'package:fl_query/src/core/retryer.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:mutex/mutex.dart';
import 'package:state_notifier/state_notifier.dart';

typedef InfiniteQueryFn<T, P> = FutureOr<T?> Function(P page);
typedef InfiniteQueryNextPage<T, P> = P? Function(
  P lastPage,
  List<T> pages,
);

class InfiniteQueryPage<T, E, P> {
  final P page;
  final T? data;
  final E? error;

  final DateTime updatedAt;
  final Duration staleDuration;

  const InfiniteQueryPage({
    required this.page,
    this.data,
    this.error,
    required this.updatedAt,
    required this.staleDuration,
  });

  bool get isStale => DateTime.now().difference(updatedAt) > staleDuration;

  InfiniteQueryPage<T, E, P> copyWith({
    T? data,
    E? error,
  }) {
    return InfiniteQueryPage<T, E, P>(
      page: page,
      updatedAt: DateTime.now(),
      staleDuration: staleDuration,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is InfiniteQueryPage<T, E, P> && other.page == page;
  }

  @override
  int get hashCode => page.hashCode;
}

class InfiniteQueryState<T, E, P> {
  final Set<InfiniteQueryPage<T, E, P>> pages;
  final InfiniteQueryFn<T, P> queryFn;
  final InfiniteQueryNextPage<T, P> nextPage;

  const InfiniteQueryState({
    required this.pages,
    required this.queryFn,
    required this.nextPage,
  });

  P get lastPage => pages.last.page;
  P? get getNextPage => nextPage(lastPage, pages.map((e) => e.data!).toList());
  bool get hasNextPage => getNextPage != null;

  InfiniteQueryState<T, E, P> copyWith({
    Set<InfiniteQueryPage<T, E, P>>? pages,
    InfiniteQueryFn<T, P>? queryFn,
    InfiniteQueryNextPage<T, P>? nextPage,
  }) {
    return InfiniteQueryState<T, E, P>(
      pages: pages ?? this.pages,
      queryFn: queryFn ?? this.queryFn,
      nextPage: nextPage ?? this.nextPage,
    );
  }
}

class InfiniteQuery<T, E, K, P>
    extends StateNotifier<InfiniteQueryState<T, E, P>> with Retryer<T, E> {
  final ValueKey<K> key;
  final RetryConfig retryConfig;
  final RefreshConfig refreshConfig;
  final JsonConfig<T>? jsonConfig;

  InfiniteQuery(
    this.key,
    InfiniteQueryFn<T, P> queryFn, {
    required InfiniteQueryNextPage<T, P> nextPage,
    required P initialParam,
    this.retryConfig = DefaultConstants.retryConfig,
    this.refreshConfig = DefaultConstants.refreshConfig,
    this.jsonConfig,
  }) : super(InfiniteQueryState<T, E, P>(
          pages: {
            InfiniteQueryPage<T, E, P>(
              page: initialParam,
              updatedAt: DateTime.now(),
              staleDuration: refreshConfig.staleDuration,
            ),
          },
          queryFn: queryFn,
          nextPage: nextPage,
        )) {
    if (jsonConfig != null) {
      _mutex.protect(() async {
        final json = await _box.get(key.value);
        if (json != null) {
          state = state.copyWith(
            pages: json.map(
              (key, value) => MapEntry(
                key as P,
                jsonConfig!.fromJson(value),
              ),
            ),
          );
        }
      });

      Timer.periodic(refreshConfig.refreshInterval, (_) async {
        await Future.wait(
          state.pages.map((page) async {
            if (page.isStale) {
              return await refresh(page.page);
            }
          }),
        );
      });
    }
  }

  final _mutex = Mutex();
  final _box = Hive.lazyBox("cache");

  List<T> get pages => state.pages.map((e) => e.data).whereType<T>().toList();
  List<E> get errors => state.pages.map((e) => e.error).whereType<E>().toList();
  P get lastPage => state.lastPage;

  bool get isLoadingPage => !hasPageData && !hasPageError && _mutex.isLocked;
  bool get isRefreshingPage => (hasPageData || hasPageError) && _mutex.isLocked;

  bool get hasPages => pages.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;

  bool get hasPageData => state.pages.last.data != null;
  bool get hasPageError => state.pages.last.error != null;

  bool get hasNextPage => state.hasNextPage;

  Future<void> _operation(P page) {
    return _mutex.protect(() async {
      retryOperation(
        () => state.queryFn(page),
        config: retryConfig,
        onSuccessful: (data) async {
          state = state.copyWith(
            pages: {
              ...state.pages,
              state.pages
                  .firstWhere(
                    (e) => e.page == page,
                    orElse: () => InfiniteQueryPage<T, E, P>(
                      page: page,
                      updatedAt: DateTime.now(),
                      staleDuration: refreshConfig.staleDuration,
                    ),
                  )
                  .copyWith(data: data),
            },
          );
          if (jsonConfig != null) {
            await _box.put(
              key.value,
              state.pages.map(
                (e) => MapEntry(
                  e.page,
                  e.data != null ? jsonConfig!.toJson(e.data!) : null,
                ),
              ),
            );
          }
        },
        onFailed: (error) {
          state = state.copyWith(
            pages: {
              ...state.pages,
              state.pages
                  .firstWhere(
                    (e) => e.page == page,
                    orElse: () => InfiniteQueryPage<T, E, P>(
                      page: page,
                      updatedAt: DateTime.now(),
                      staleDuration: refreshConfig.staleDuration,
                    ),
                  )
                  .copyWith(error: error),
            },
          );
        },
      );
    });
  }

  Future<T?> fetch() async {
    final lastPage = state.lastPage;
    if (_mutex.isLocked || hasPageData || hasPageError)
      return state.pages.last.data;
    return await _operation(lastPage).then((_) => state.pages.last.data);
  }

  Future<T?> refresh([P? page]) async {
    page ??= lastPage;
    if (_mutex.isLocked)
      return state.pages.firstWhereOrNull((e) => e.page == page)?.data;
    return await _operation(page!).then((_) {
      return state.pages.firstWhereOrNull((e) => e.page == page)?.data;
    });
  }

  Future<List<T>?> refreshAll() async {
    if (_mutex.isLocked) return pages;
    return await Future.wait(
      state.pages.map((e) => _operation(e.page)),
    ).then((_) => pages);
  }

  Future<T?> fetchNext() async {
    final nextPage = state.getNextPage;
    if (_mutex.isLocked || nextPage != null) {
      return state.pages.firstWhereOrNull((e) => e.page == nextPage)?.data;
    }
    return await _operation(nextPage!).then((_) {
      return state.pages.firstWhereOrNull((e) => e.page == nextPage)?.data;
    });
  }
}
