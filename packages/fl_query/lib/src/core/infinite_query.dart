import 'dart:async';

import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:fl_query/src/collections/json_config.dart';
import 'package:fl_query/src/collections/refresh_config.dart';
import 'package:fl_query/src/collections/retry_config.dart';
import 'package:fl_query/src/core/client.dart';
import 'package:fl_query/src/core/mixins/retryer.dart';
import 'package:fl_query/src/core/mixins/validation.dart';
import 'package:fl_query/src/widgets/state_resolvers/infinite_query_state.dart';
import 'package:flutter/widgets.dart' hide Listener;
import 'package:hive_flutter/adapters.dart';
import 'package:mutex/mutex.dart';
import 'package:state_notifier/state_notifier.dart';

typedef InfiniteQueryFn<DataType, PageType> = FutureOr<DataType?> Function(
    PageType page);
typedef InfiniteQueryNextPage<DataType, PageType> = PageType? Function(
  PageType lastPage,
  DataType lastPageData,
);

/// A page holding all the data for a given page
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

  InfiniteQueryState({
    required this.pages,
  });

  PageType get lastPage => pages.last.page;

  InfiniteQueryState<DataType, ErrorType, PageType> copyWith(
      {Set<InfiniteQueryPage<DataType, ErrorType, PageType>>? pages}) {
    return InfiniteQueryState<DataType, ErrorType, PageType>(
      pages: pages ?? this.pages,
    );
  }
}

/// Event fired with data and error by the [InfiniteQuery] fetchPage operation
@immutable
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

/// A specialized Query that can retrieve + hold paginated/segmented data
///
/// - [nextPage] provides the next page param for fetching
/// - [initialParam] provides the initial page param for fetching
///
/// Use the [InfiniteQueryBuilder] create and use an [InfiniteQuery]
class InfiniteQuery<DataType, ErrorType, PageType>
    extends StateNotifier<InfiniteQueryState<DataType, ErrorType, PageType>>
    with Retryer<DataType, ErrorType> {
  final String key;
  final RetryConfig retryConfig;
  final RefreshConfig refreshConfig;
  final JsonConfig<DataType>? jsonConfig;

  final PageType _initialParam;

  InfiniteQueryFn<DataType, PageType> _queryFn;
  InfiniteQueryNextPage<DataType, PageType> _nextPage;

  InfiniteQuery(
    this.key,
    InfiniteQueryFn<DataType, PageType> queryFn, {
    required InfiniteQueryNextPage<DataType, PageType> nextPage,
    required PageType initialParam,
    required this.retryConfig,
    required this.refreshConfig,
    this.jsonConfig,
  })  : _initialParam = initialParam,
        _dataController = StreamController.broadcast(),
        _errorController = StreamController.broadcast(),
        _box = Hive.lazyBox(QueryClient.infiniteQueryCachePrefix),
        _queryFn = queryFn,
        _nextPage = nextPage,
        super(InfiniteQueryState<DataType, ErrorType, PageType>(
          pages: {
            InfiniteQueryPage<DataType, ErrorType, PageType>(
              page: initialParam,
              updatedAt: DateTime.now(),
              staleDuration: refreshConfig.staleDuration,
            ),
          },
        )) {
    if (jsonConfig != null) {
      _mutex.protect(() async {
        final Map? json = await _box.get(key);
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

    // Listen to network changes and cancel any ongoing operations

    bool wasConnected = true;
    _connectivitySubscription = QueryClient.connectivity.onConnectivityChanged
        .listen((isConnected) async {
      try {
        if (isConnected &&
            !wasConnected &&
            refreshConfig.refreshOnNetworkStateChange) {
          for (final page in state.pages) {
            if (page.isStale) {
              await refresh(page.page);
            }
          }
        } else if (!isConnected &&
            _mutex.isLocked &&
            retryConfig.cancelWhenOffline) {
          await _operation?.cancel();
        }
      } finally {
        wasConnected = isConnected;
      }
    });
  }

  final _mutex = Mutex();
  final LazyBox _box;
  final StreamController<PageEvent<DataType, PageType>> _dataController;
  final StreamController<PageEvent<ErrorType, PageType>> _errorController;
  StreamSubscription<bool>? _connectivitySubscription;

  CancelableOperation<void>? _operation;

  /// All the pages that has been successfully fetched
  List<DataType> get pages =>
      state.pages.map((e) => e.data).whereType<DataType>().toList();

  /// All the errors of pages that has failed to fetch
  List<ErrorType> get errors =>
      state.pages.map((e) => e.error).whereType<ErrorType>().toList();

  /// The last page that has been fetched
  PageType get lastPage => state.lastPage;

  /// Stream of data events
  ///
  /// Subscribe to it to get notified when a page data is
  /// fetched/refreshed/retried
  Stream<PageEvent<DataType, PageType>> get dataStream =>
      _dataController.stream;

  /// Stream of error events
  ///
  /// Subscribe to it to get notified when a page has failed
  Stream<PageEvent<ErrorType, PageType>> get errorStream =>
      _errorController.stream;

  /// The next page param that will be used to fetch the next page
  PageType? get getNextPage {
    final lastPageData = state.pages
        .firstWhereOrNull((e) => e.data is DataType && e.page == lastPage)
        ?.data;

    if (lastPageData == null) return null;

    return _nextPage(lastPage, lastPageData);
  }

  bool get isLoadingPage => !hasPageData && !hasPageError && _mutex.isLocked;
  bool get isRefreshingPage => (hasPageData || hasPageError) && _mutex.isLocked;
  bool get isInactive => !hasListeners;

  bool get hasPages => pages.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;

  bool get hasPageData => !hasPages ? false : state.pages.last.data != null;
  bool get hasPageError => !hasPages ? false : state.pages.last.error != null;

  bool get hasNextPage => getNextPage != null;

  Future<void> _operate(PageType page) async {
    if (!await QueryClient.connectivity.isConnected &&
        retryConfig.cancelWhenOffline) {
      return;
    }
    return _mutex.protect(() async {
      state = state.copyWith();
      _operation = cancellableRetryOperation(
        () => _queryFn(page),
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
              .copyWith(data: data, error: null);
          state = state.copyWith(
            pages: {...state.pages..remove(dataPage), dataPage},
          );
          if (dataPage.data is DataType) {
            _dataController.add(PageEvent.fromPage(dataPage));
            if (jsonConfig != null) {
              await _box.put(
                key,
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

  /// Fetch current non-fetched page
  ///
  /// If page is already done fetching. It'll simply returns the old data
  Future<DataType?> fetch() async {
    final lastPage = state.lastPage;
    if (_mutex.isLocked || hasPageData || hasPageError)
      return state.pages.last.data;
    return await _operate(lastPage).then((_) => state.pages.last.data);
  }

  /// Refresh a page that has or has not been fetched
  ///
  /// - [page] The page to refresh. If null, it'll refresh the last page
  Future<DataType?> refresh([PageType? page]) async {
    page ??= lastPage;
    if (_mutex.isLocked)
      return state.pages.firstWhereOrNull((e) => e.page == page)?.data;
    return await _operate(page!).then((_) {
      return state.pages.firstWhereOrNull((e) => e.page == page)?.data;
    });
  }

  /// Refresh all the pages that has been fetched
  Future<List<DataType>?> refreshAll() async {
    if (_mutex.isLocked) return pages;
    return await Future.wait(
      state.pages.map((e) => _operate(e.page)),
    ).then((_) => pages);
  }

  /// Fetch the next page
  ///
  /// If there's no next page, it'll simply return the last page data
  Future<DataType?> fetchNext() async {
    final nextPage = getNextPage;
    if (_mutex.isLocked || nextPage == null) {
      return state.pages.lastOrNull?.data;
    }
    return await _operate(nextPage).then((_) {
      return state.pages.firstWhereOrNull((e) => e.page == nextPage)?.data;
    });
  }

  /// Replace the currently [queryFn] with new [queryFn]
  ///
  /// This is internally used to update queryFn when external data
  /// has changed. Used by [InfiniteQueryBuilder] and [QueryClient]
  ///
  /// This can also refresh if [RefreshConfig.refreshOnQueryFnChange] is true
  void updateQueryFn(InfiniteQueryFn<DataType, PageType> queryFn) {
    if (_queryFn == queryFn) return;
    _queryFn = queryFn;
    if (refreshConfig.refreshOnQueryFnChange) {
      refreshAll();
    } else {
      Future.wait(
        state.pages.map((page) async {
          if (page.isStale && page.error == null) {
            return await refresh(page.page);
          }
        }),
      );
    }
  }

  /// Replace the currently [nextPage] with new [nextPage]
  void updateNextPageFn(InfiniteQueryNextPage<DataType, PageType> nextPage) {
    if (_nextPage == nextPage) return;
    _nextPage = nextPage;
  }

  /// Manually set the data of a page
  ///
  /// If there's no page with the given [page], it'll create a new page
  /// and set the data as the given [data]
  ///
  /// The new page will be added to the end of the list so it becomes [lastPage]
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

  Widget resolve(
    Widget Function(List<DataType> data) data, {
    required Widget Function(List<ErrorType> errors) error,
    required Widget Function() loading,
    Widget Function()? offline,
  }) {
    if (hasPages) {
      return data(this.pages);
    } else if (!QueryClient.connectivity.isConnectedSync) {
      return offline != null ? offline() : loading();
    } else if (hasErrors) {
      return error(this.errors);
    } else {
      return loading();
    }
  }

  Widget resolveWith(
    BuildContext context,
    Widget Function(List<DataType> data) data, {
    required Widget Function(List<ErrorType> error)? error,
    required Widget Function()? loading,
    Widget Function()? offline,
  }) {
    final resolvents = InfiniteQueryStateResolverProvider.of(context);

    assert(
      resolvents.error != null || error != null,
      'You must provide an error widget or an error resolver using `InfiniteQueryStateResolverProvider`',
    );

    assert(
      resolvents.loading != null || loading != null,
      'You must provide a loading widget or a loading resolver using `InfiniteQueryStateResolverProvider`',
    );

    return resolve(
      data,
      error: resolvents.error != null
          ? (e) => resolvents.error!(e.cast<dynamic>())
          : error!,
      loading: (resolvents.loading ?? loading)!,
      offline: resolvents.offline ?? offline,
    );
  }

  /// Reset all data, pages, error, events of this query
  ///
  /// This will also remove every data of this [InfiniteQuery] from
  /// persistent cache
  Future<void> reset() async {
    await _operation?.cancel();
    state = state.copyWith(pages: {
      InfiniteQueryPage<DataType, ErrorType, PageType>(
        page: _initialParam,
        updatedAt: DateTime.now(),
        staleDuration: refreshConfig.staleDuration,
      )
    });
    _box.delete(key);
  }

  @override
  RemoveListener addListener(
    Listener<InfiniteQueryState<DataType, ErrorType, PageType>> listener, {
    bool fireImmediately = true,
  }) {
    Future.microtask(() async {
      if (refreshConfig.refreshOnMount) {
        await refreshAll();
      } else {
        await Future.wait(
          state.pages.map((page) async {
            if (page.isStale) {
              return await refresh(page.page);
            }
          }),
        );
      }
    });
    return super.addListener(listener, fireImmediately: fireImmediately);
  }

  @override
  void dispose() {
    _operation?.cancel();
    _connectivitySubscription?.cancel();
    _errorController.close();
    _dataController.close();
    super.dispose();
  }

  @override
  operator ==(Object other) =>
      identical(this, other) || other is InfiniteQuery && key == other.key;

  @override
  int get hashCode => key.hashCode;

  InfiniteQuery<NewDataType, NewErrorType, NewPageType>
      cast<NewDataType, NewErrorType, NewPageType>() {
    return this as InfiniteQuery<NewDataType, NewErrorType, NewPageType>;
  }
}
