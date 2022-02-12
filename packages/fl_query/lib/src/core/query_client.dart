import 'package:fl_query/src/core/models.dart';
import 'package:fl_query/src/core/notify_manager.dart';
import 'package:fl_query/src/core/online_manager.dart';
import 'package:fl_query/src/core/query.dart';
import 'package:fl_query/src/core/query_cache.dart';
import 'package:fl_query/src/core/query_key.dart';
import 'package:fl_query/src/core/query_observer.dart';
import 'package:fl_query/src/core/utils.dart';
import 'package:collection/collection.dart';

class QueryDefaults {
  QueryKey queryKey;
  QueryOptions defaultOptions;
  QueryDefaults({
    required this.queryKey,
    required this.defaultOptions,
  });
}

class MutationDefaults {
  // QueryKey queryKey;
  // QueryOptions defaultOptions;
  // MutationDefaults({
  //   required this.queryKey,
  //   required this.defaultOptions,
  // });
}

class QueryData<TData> {
  QueryKey queryKey;
  TData data;
  QueryData({
    required this.queryKey,
    required this.data,
  });
}

class QueryClient {
  QueryCache _queryCache;
  // QueryCache _mutationCache;
  DefaultOptions _defaultOptions;
  List<QueryDefaults> _queryDefaults;
  // List<MutationDefaults> _mutationDefaults;
  void Function()? _unsubscribeFocus;
  void Function()? _unsubscribeOnline;
  // MutationKey _mutationKey;
  // MutationOptions<any, any, any, any> _mutationDefaultOptions;

  QueryClient({
    QueryCache? queryCache,
    QueryCache? mutationCache,
    DefaultOptions? defaultOptions,
  })  : _queryCache = queryCache ?? QueryCache(),
        _defaultOptions = defaultOptions ?? DefaultOptions(),
        _queryDefaults = [];
  /* _mutationDefaults = [], */
  /* _mutationCache = mutationCache ?? QueryCache() */

  void mount() {
    // this.unsubscribeFocus = focusManager.subscribe(() => {
    //   if (focusManager.isFocused() && onlineManager.isOnline()) {
    //     this.mutationCache.onFocus()
    //     this.queryCache.onFocus()
    //   }
    // })
    _unsubscribeOnline = onlineManager.subscribe(() async {
      if (/* focusManager.isFocused() && */ await onlineManager.isOnline()) {
        // _mutationCache.onOnline();
        _queryCache.onOnline();
      }
    });
  }

  void unmount() {
    _unsubscribeFocus?.call();
    _unsubscribeOnline?.call();
  }

  int isFetching({QueryKey? queryKey, QueryFilters? filters}) {
    filters?.fetching = true;
    return _queryCache.findAll(null, filters).length;
  }

  // int isMutating([MutationFilters? filters]) {
  //   return _mutationCache.findAll({ ...filters, fetching: true }).length
  // }

  TData? getQueryData<TData>(
    QueryKey queryKey, [
    QueryFilters? filters,
  ]) {
    return _queryCache
        .find<TData, dynamic, dynamic>(queryKey, filters ?? QueryFilters())
        ?.state
        .data;
  }

  List<QueryData<TData>> getQueriesData<TData>({
    QueryKey? queryKey,
    QueryFilters? filters,
  }) {
    return getQueryCache().findAll(queryKey, filters).map((query) {
      return QueryData<TData>(
        data: query.state.data as TData,
        queryKey: query.queryKey,
      );
    }).toList();
  }

  TData setQueryData<TData>(
    QueryKey queryKey,
    DataUpdateFunction<TData?, TData> updater, [
    DateTime? updatedAt,
  ]) {
    var defaultedOptions =
        defaultQueryOptions(QueryObserverOptions(queryKey: queryKey));
    return _queryCache.build(this, defaultedOptions).setData(
          updater as Function(dynamic),
          updatedAt: updatedAt,
        );
  }

  List<QueryData> setQueriesData<TData>({
    required DataUpdateFunction<TData?, TData> updater,
    QueryKey? queryKey,
    QueryFilters? filters,
    DateTime? updatedAt,
  }) {
    if (queryKey == null && filters == null)
      throw Exception(
          "[QueryClient.setQueriesData] both `queryKey` & `filters` can't be null at the same time");
    return notifyManager
        .batch(() => getQueryCache().findAll(queryKey, filters).map(
              (query) => QueryData(
                queryKey: query.queryKey,
                data: setQueryData<TData>(
                  query.queryKey,
                  updater,
                  updatedAt,
                ),
              ),
            ))
        .toList();
  }

  QueryState<TData, TError>? getQueryState<TData, TError>(
    QueryKey,
    queryKey, [
    QueryFilters? filters,
  ]) {
    return _queryCache
        .find<TData, TError, dynamic>(
          queryKey,
          filters ?? QueryFilters(),
        )
        ?.state as QueryState<TData, TError>?;
  }

  void removeQueries({QueryKey? queryKey, QueryFilters? filters}) {
    notifyManager.batch(
      () => {
        _queryCache.findAll(queryKey, filters).forEach((query) {
          _queryCache.remove(query);
        })
      },
    );
  }

  Future<void> resetQueries<TPageData>({
    QueryKey? queryKey,
    RefetchableQueryFilters<TPageData>? filters,
    bool? throwOnError,
  }) {
    filters?.active = true;
    var refetchFilters = RefetchableQueryFilters<TPageData>.fromJson({
      ...(filters?.toJson() ?? {}),
      "active": true,
    });

    return notifyManager.batch(() {
      _queryCache.findAll(queryKey, filters).forEach((query) {
        query.reset();
      });
      return refetchQueries(
        filters: refetchFilters,
        options: RefetchOptions(throwOnError: throwOnError),
      );
    });
  }

  Future<void> cancelQueries({
    QueryKey? queryKey,
    QueryFilters? filters,
    bool? revert = true,
    bool? silent,
  }) {
    var futures = notifyManager.batch(() =>
        _queryCache.findAll(queryKey, filters).map((query) => query.cancel(
              revert: revert,
              silent: silent,
            )));
    return Future.wait(futures).then(noop).catchError(noop);
  }

  Future<void> invalidateQueries<TPageData>({
    QueryKey? queryKey,
    InvalidateQueryFilters<TPageData>? filters,
    RefetchOptions? options,
  }) {
    var refetchFilters = RefetchableQueryFilters<TPageData>.fromJson({
      ...(filters?.toJson() ?? {}),
      // if filters.refetchActive is not provided and filters.active is explicitly false,
      // e.g. invalidateQueries({ active: false }), we don't want to refetch active queries
      "active": filters?.refetchActive ?? filters?.active ?? true,
      "inactive": filters?.refetchInactive ?? false,
    });
    return notifyManager.batch(() {
      _queryCache.findAll(queryKey, filters).forEach((query) {
        query.invalidate();
      });
      return this.refetchQueries(
        filters: refetchFilters,
        options: options,
      );
    });
  }

  Future<void> refetchQueries<TPageData>({
    QueryKey? queryKey,
    RefetchableQueryFilters<TPageData>? filters,
    RefetchOptions? options,
  }) {
    var futures = notifyManager.batch(
      () => _queryCache.findAll(queryKey, filters).map(
            (query) => query.fetch(
              null,
              ObserverFetchOptions(
                cancelRefetch: options?.cancelRefetch,
                throwOnError: options?.throwOnError,
                meta: {"refetchPage": filters?.refetchPage},
              ),
            ),
          ),
    );

    var future = Future.wait(futures).then(noop);

    if (options?.throwOnError == false) {
      future = future.catchError(noop);
    }

    return future;
  }

  Future<TData> fetchQuery<TQueryFnData, TError, TData>({
    QueryKey? queryKey,
    QueryFunction<TQueryFnData, dynamic>? queryFn,
    FetchQueryOptions<TQueryFnData, TError, TData>? options,
  }) {
    var defaultedOptions = this.defaultQueryOptions(
      QueryObserverOptions(
        queryFn: queryFn,
        queryKey: queryKey,
        staleTime: options?.staleTime,
        cacheTime: options?.cacheTime,
        defaulted: options?.defaulted,
        initialData: options?.initialData,
        initialDataUpdatedAt: options?.initialDataUpdatedAt,
        isDataEqual: options?.isDataEqual,
        meta: options?.meta,
        queryHash: options?.queryHash,
        queryKeyHashFn: options?.queryKeyHashFn,
        structuralSharing: options?.structuralSharing,
      ),
    );
    // returning 0 indicates turing off retry
    defaultedOptions.retry ??= (_, __) => 0;
    var query = _queryCache.build(this, defaultedOptions);
    return query.isStaleByTime(defaultedOptions.staleTime)
        ? query.fetch(defaultedOptions)
        : Future.value(query.state.data as TData);
  }

  Future<void> prefetchQuery<TQueryFnData, TError, TData>({
    QueryKey? queryKey,
    QueryFunction<TQueryFnData, dynamic>? queryFn,
    FetchQueryOptions<TQueryFnData, TError, TData>? options,
  }) {
    return fetchQuery(
      queryKey: queryKey,
      queryFn: queryFn,
      options: options,
    ).then(noop).catchError(noop);
  }

  QueryObserverOptions<TQueryFnData, TError, TData, TQueryData>
      defaultQueryOptions<TQueryFnData, TError, TData, TQueryData>(
          QueryObserverOptions<TQueryFnData, TError, TData, TQueryData>?
              options) {
    if (options?.defaulted == true) return options!;
    var defaultedOptions =
        QueryObserverOptions<TQueryFnData, TError, TData, TQueryData>.fromJson({
      ...(_defaultOptions.queries?.toJson() ?? {}),
      ...(getQueryDefaults(options?.queryKey)?.toJson() ?? {}),
      ...(options?.toJson() ?? {}),
      "defaulted": true,
    });
    if (defaultedOptions.queryHash == null &&
        defaultedOptions.queryKey != null) {
      defaultedOptions.queryHash = hashQueryKeyByOptions(
        defaultedOptions.queryKey!,
        defaultedOptions,
      );
    }

    return defaultedOptions;
  }

  QueryObserverOptions<TQueryFnData, TError, TData, TQueryData>
      defaultQueryObserverOptions<TQueryFnData, TError, TData, TQueryData>([
    QueryObserverOptions<TQueryFnData, TError, TData, TQueryData>? options,
  ]) {
    return this.defaultQueryOptions(options);
  }

  DefaultOptions getDefaultOptions() {
    return _defaultOptions;
  }

  void setDefaultOptions(DefaultOptions options) {
    _defaultOptions = options;
  }

  QueryObserverOptions? getQueryDefaults([QueryKey? queryKey]) {
    return queryKey != null
        ? QueryObserverOptions.fromJson((_queryDefaults
                    .firstWhereOrNull(
                      (x) => queryKey.key == x.queryKey.key,
                    )
                    ?.defaultOptions)
                ?.toJson() ??
            {})
        : null;
  }

  void setQueryDefaults(QueryKey queryKey, QueryObserverOptions options) {
    var result = _queryDefaults.firstWhereOrNull(
      (x) => queryKey.key == x.queryKey.key,
    );

    if (result != null) {
      result.defaultOptions = options;
    } else {
      _queryDefaults
          .add(QueryDefaults(queryKey: queryKey, defaultOptions: options));
    }
  }

  // getMutationDefaults() {}
  // setMutationDefaults() {}
  // getMutationCache() {}

  QueryCache getQueryCache() {
    return _queryCache;
  }

  void clear() {
    _queryCache.clear();
    // _mutationCache.clear();
  }
}
