import 'dart:async';

import 'package:collection/collection.dart';
import 'package:fl_query/src/collections/default_configs.dart';
import 'package:fl_query/src/collections/json_config.dart';
import 'package:fl_query/src/collections/refresh_config.dart';
import 'package:fl_query/src/collections/retry_config.dart';
import 'package:fl_query/src/core/retryer.dart';
import 'package:fl_query/src/core/validation.dart';
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

class InfiniteQueryPage<DataType, ErrorType, PageType> with Invalidation {
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
  final InfiniteQueryNextPage<DataType, PageType> _nextPage;

  const InfiniteQueryState({
    required this.pages,
    required this.queryFn,
    required InfiniteQueryNextPage<DataType, PageType> nextPage,
  }) : _nextPage = nextPage;

  PageType get lastPage => pages.last.page;
  PageType? get getNextPage => _nextPage(
        lastPage,
        pages.map((e) => e.data).whereType<DataType>().toList(),
      );

  bool get hasNextPage => getNextPage != null;

  InfiniteQueryState<DataType, ErrorType, PageType> copyWith({
    Set<InfiniteQueryPage<DataType, ErrorType, PageType>>? pages,
    InfiniteQueryFn<DataType, PageType>? queryFn,
    InfiniteQueryNextPage<DataType, PageType>? nextPage,
  }) {
    return InfiniteQueryState<DataType, ErrorType, PageType>(
      pages: pages ?? this.pages,
      queryFn: queryFn ?? this.queryFn,
      nextPage: nextPage ?? this._nextPage,
    );
  }
}

class PageEvent<T, P> {
  final P page;
  final T data;
  const PageEvent(this.page, this.data);

  factory PageEvent.fromPage(
    InfiniteQueryPage page,
  ) {
    return PageEvent(page.page as P, page.data as T);
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
  })  : _dataController = StreamController.broadcast(),
        _errorController = StreamController.broadcast(),
        super(InfiniteQueryState<DataType, ErrorType, PageType>(
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
        final Map? json = await _box.get(key.value);
        if (json != null) {
          state = state.copyWith(
            pages: json.entries
                .map(
                  (entry) => InfiniteQueryPage<DataType, ErrorType, PageType>(
                    page: entry.key as PageType,
                    data: jsonConfig!.fromJson(
                        Map.castFrom<dynamic, dynamic, String, dynamic>(
                      entry.value,
                    )),
                    // this makes the page loaded from cache `stale`
                    updatedAt:
                        DateTime.now().subtract(refreshConfig.staleDuration),
                    staleDuration: refreshConfig.staleDuration,
                  ),
                )
                .toSet(),
          );
        }
      }).then((_) {
        if (hasListeners) {
          return fetch();
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
  final StreamController<PageEvent<DataType, PageType>> _dataController;
  final StreamController<PageEvent<ErrorType, PageType>> _errorController;

  List<DataType> get pages =>
      state.pages.map((e) => e.data).whereType<DataType>().toList();
  List<ErrorType> get errors =>
      state.pages.map((e) => e.error).whereType<ErrorType>().toList();
  PageType get lastPage => state.lastPage;
  Stream<PageEvent<DataType, PageType>> get dataStream =>
      _dataController.stream;
  Stream<PageEvent<ErrorType, PageType>> get errorStream =>
      _errorController.stream;

  bool get isLoadingPage => !hasPageData && !hasPageError && _mutex.isLocked;
  bool get isRefreshingPage => (hasPageData || hasPageError) && _mutex.isLocked;
  bool get isInactive => !hasListeners;

  bool get hasPages => pages.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;

  bool get hasPageData => !hasPages ? false : state.pages.last.data != null;
  bool get hasPageError => !hasPages ? false : state.pages.last.error != null;

  bool get hasNextPage => state.hasNextPage;

  Future<void> _operation(PageType page) {
    return _mutex.protect(() async {
      return await retryOperation(
        () => state.queryFn(page),
        config: retryConfig,
        onSuccessful: (data) async {
          final dataPage = state.pages
              .firstWhere(
                (e) => e.page == page,
                orElse: () => InfiniteQueryPage<DataType, ErrorType, PageType>(
                  page: page,
                  updatedAt: DateTime.now(),
                  staleDuration: refreshConfig.staleDuration,
                ),
              )
              .copyWith(data: data);
          state = state.copyWith(
            pages: {...state.pages..remove(dataPage), dataPage},
          );
          if (dataPage.data is DataType) {
            _dataController.add(PageEvent.fromPage(dataPage));
            if (jsonConfig != null) {
              await _box.put(
                key.value,
                Map.fromEntries(
                  state.pages.map(
                    (e) => MapEntry(
                      e.page,
                      e.data != null ? jsonConfig!.toJson(e.data!) : null,
                    ),
                  ),
                ),
              );
            }
          }
        },
        onFailed: (error) {
          final errorPage = state.pages
              .firstWhere(
                (e) => e.page == page,
                orElse: () => InfiniteQueryPage<DataType, ErrorType, PageType>(
                  page: page,
                  updatedAt: DateTime.now(),
                  staleDuration: refreshConfig.staleDuration,
                ),
              )
              .copyWith(error: error);
          state = state.copyWith(
            pages: {
              ...state.pages..remove(errorPage),
              errorPage,
            },
          );
          if (errorPage.error is ErrorType)
            _errorController.add(PageEvent.fromPage(errorPage));
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
    if (_mutex.isLocked || nextPage == null) {
      return state.pages.lastOrNull?.data;
    }
    return await _operation(nextPage).then((_) {
      return state.pages.firstWhereOrNull((e) => e.page == nextPage)?.data;
    });
  }

  void updateQueryFn(InfiniteQueryFn<DataType, PageType> queryFn) {
    if (state.queryFn == queryFn) return;
    state = state.copyWith(queryFn: queryFn);
    if (refreshConfig.refreshOnQueryFnChange) {
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
  }

  void updateNextPageFn(InfiniteQueryNextPage<DataType, PageType> nextPage) {
    state = state.copyWith(nextPage: nextPage);
  }

  void setPageData(PageType page, DataType data) {
    final newPage = state.pages
        .firstWhere(
          (e) => e.page == page,
          orElse: () => InfiniteQueryPage<DataType, ErrorType, PageType>(
            page: page,
            updatedAt: DateTime.now(),
            staleDuration: refreshConfig.staleDuration,
          ),
        )
        .copyWith(data: data);

    state = state.copyWith(
      pages: {
        ...state.pages..remove(newPage),
        newPage,
      },
    );
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

  @override
  int get hashCode => key.hashCode;

  InfiniteQuery<NewDataType, NewErrorType, NewKeyType, NewPageType>
      cast<NewDataType, NewErrorType, NewKeyType, NewPageType>() {
    return this
        as InfiniteQuery<NewDataType, NewErrorType, NewKeyType, NewPageType>;
  }
}
