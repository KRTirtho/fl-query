import 'dart:async';

import 'package:collection/collection.dart';
import 'package:fl_query/src/collections/default_configs.dart';
import 'package:fl_query/src/collections/json_config.dart';
import 'package:fl_query/src/collections/refresh_config.dart';
import 'package:fl_query/src/collections/retry_config.dart';
import 'package:fl_query/src/core/retryer.dart';
import 'package:flutter/material.dart' hide Listener;
import 'package:hive_flutter/adapters.dart';
import 'package:mutex/mutex.dart';
import 'package:state_notifier/state_notifier.dart';

typedef InfiniteQueryFn<DataType, PageType> = FutureOr<DataType?> Function(
    PageType page);
typedef InfiniteQueryNextPage<DataType, PageType> = PageType? Function(
  PageType lastPage,
  List<DataType> pages,
);

class InfiniteQueryPage<DataType, ErrorType, PageType> {
  final PageType page;
  final DataType? data;
  final ErrorType? error;

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

  InfiniteQueryPage<DataType, ErrorType, PageType> copyWith({
    DataType? data,
    ErrorType? error,
  }) {
    return InfiniteQueryPage<DataType, ErrorType, PageType>(
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

    return other is InfiniteQueryPage<DataType, ErrorType, PageType> &&
        other.page == page;
  }

  @override
  int get hashCode => page.hashCode;
}

class InfiniteQueryState<DataType, ErrorType, PageType> {
  final Set<InfiniteQueryPage<DataType, ErrorType, PageType>> pages;
  final InfiniteQueryFn<DataType, PageType> queryFn;
  final InfiniteQueryNextPage<DataType, PageType> nextPage;

  const InfiniteQueryState({
    required this.pages,
    required this.queryFn,
    required this.nextPage,
  });

  PageType get lastPage => pages.last.page;
  PageType? get getNextPage =>
      nextPage(lastPage, pages.map((e) => e.data!).toList());
  bool get hasNextPage => getNextPage != null;

  InfiniteQueryState<DataType, ErrorType, PageType> copyWith({
    Set<InfiniteQueryPage<DataType, ErrorType, PageType>>? pages,
    InfiniteQueryFn<DataType, PageType>? queryFn,
    InfiniteQueryNextPage<DataType, PageType>? nextPage,
  }) {
    return InfiniteQueryState<DataType, ErrorType, PageType>(
      pages: pages ?? this.pages,
      queryFn: queryFn ?? this.queryFn,
      nextPage: nextPage ?? this.nextPage,
    );
  }
}

class InfiniteQuery<DataType, ErrorType, KeyType, PageType>
    extends StateNotifier<InfiniteQueryState<DataType, ErrorType, PageType>>
    with Retryer<DataType, ErrorType> {
  final ValueKey<KeyType> key;
  final RetryConfig retryConfig;
  final RefreshConfig refreshConfig;
  final JsonConfig<DataType>? jsonConfig;

  InfiniteQuery(
    this.key,
    InfiniteQueryFn<DataType, PageType> queryFn, {
    required InfiniteQueryNextPage<DataType, PageType> nextPage,
    required PageType initialParam,
    this.retryConfig = DefaultConstants.retryConfig,
    this.refreshConfig = DefaultConstants.refreshConfig,
    this.jsonConfig,
  }) : super(InfiniteQueryState<DataType, ErrorType, PageType>(
          pages: {
            InfiniteQueryPage<DataType, ErrorType, PageType>(
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
        final json = await _box.get(key.toString());
        if (json != null) {
          state = state.copyWith(
            pages: json.map(
              (key, value) => MapEntry(
                key as PageType,
                jsonConfig!.fromJson(value),
              ),
            ),
          );
        }
      });
    }
    if (refreshConfig.refreshInterval > Duration.zero)
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

  final _mutex = Mutex();
  final _box = Hive.lazyBox("cache");

  List<DataType> get pages =>
      state.pages.map((e) => e.data).whereType<DataType>().toList();
  List<ErrorType> get errors =>
      state.pages.map((e) => e.error).whereType<ErrorType>().toList();
  PageType get lastPage => state.lastPage;

  bool get isLoadingPage => !hasPageData && !hasPageError && _mutex.isLocked;
  bool get isRefreshingPage => (hasPageData || hasPageError) && _mutex.isLocked;
  bool get isInactive => !hasListeners;

  bool get hasPages => pages.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;

  bool get hasPageData => state.pages.last.data != null;
  bool get hasPageError => state.pages.last.error != null;

  bool get hasNextPage => state.hasNextPage;

  Future<void> _operation(PageType page) {
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
                    orElse: () =>
                        InfiniteQueryPage<DataType, ErrorType, PageType>(
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
              key.toString(),
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
                    orElse: () =>
                        InfiniteQueryPage<DataType, ErrorType, PageType>(
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

  Future<DataType?> fetch() async {
    final lastPage = state.lastPage;
    if (_mutex.isLocked || hasPageData || hasPageError)
      return state.pages.last.data;
    return await _operation(lastPage).then((_) => state.pages.last.data);
  }

  Future<DataType?> refresh([PageType? page]) async {
    page ??= lastPage;
    if (_mutex.isLocked)
      return state.pages.firstWhereOrNull((e) => e.page == page)?.data;
    return await _operation(page!).then((_) {
      return state.pages.firstWhereOrNull((e) => e.page == page)?.data;
    });
  }

  Future<List<DataType>?> refreshAll() async {
    if (_mutex.isLocked) return pages;
    return await Future.wait(
      state.pages.map((e) => _operation(e.page)),
    ).then((_) => pages);
  }

  Future<DataType?> fetchNext() async {
    final nextPage = state.getNextPage;
    if (_mutex.isLocked || nextPage != null) {
      return state.pages.firstWhereOrNull((e) => e.page == nextPage)?.data;
    }
    return await _operation(nextPage!).then((_) {
      return state.pages.firstWhereOrNull((e) => e.page == nextPage)?.data;
    });
  }

  @override
  RemoveListener addListener(
    Listener<InfiniteQueryState<DataType, ErrorType, PageType>> listener, {
    bool fireImmediately = true,
  }) {
    if (refreshConfig.refreshOnMount) {
      refreshAll();
    } else {
      Future.wait(
        state.pages.map((page) async {
          if (page.isStale) {
            return await refresh(page.page);
          }
        }),
      );
    }
    return super.addListener(listener, fireImmediately: fireImmediately);
  }

  @override
  operator ==(Object other) =>
      identical(this, other) || other is InfiniteQuery && key == other.key;
}
