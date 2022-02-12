/// `TQueryData`, `TQueryFnData`, `TData` should be [Map]s for shallow/deep equality checks
/// Or these can be data classes that have `toJson` method & `fromJson`
/// constructor. This also requires the data-class to be passed to the
/// [Query] constructor parameters e.g ([dataType])

import 'dart:async';

import 'package:fl_query/src/core/models.dart';
import 'package:fl_query/src/core/notify_manager.dart';
import 'package:fl_query/src/core/query.dart';
import 'package:fl_query/src/core/query_cache.dart';
import 'package:fl_query/src/core/query_client.dart';
import 'package:fl_query/src/core/retryer.dart';
import 'package:fl_query/src/core/subscribable.dart';
import 'package:fl_query/src/core/utils.dart';
import 'package:meta/meta.dart';

typedef QueryObserverListener<TData, TError> = void Function(
    QueryObserverResult<TData, TError> result);

class NotifyOptions {
  bool? cache;
  bool? listeners;
  bool? onError;
  bool? onSuccess;

  NotifyOptions({this.cache, this.listeners, this.onError, this.onSuccess});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['cache'] = this.cache;
    data['listeners'] = this.listeners;
    data['onError'] = this.onError;
    data['onSuccess'] = this.onSuccess;
    return data;
  }

  NotifyOptions.fromJson(Map<String, dynamic> json) {
    cache = json['cache'];
    listeners = json['listeners'];
    onError = json['onError'];
    onSuccess = json['onSuccess'];
  }
}

class ObserverFetchOptions extends FetchOptions {
  bool? throwOnError;
  ObserverFetchOptions({
    this.throwOnError,
    bool? cancelRefetch,
    dynamic meta,
  }) : super(cancelRefetch: cancelRefetch, meta: meta);
}

class SelectQuery<TQueryData, TData> {
  TData Function(TQueryData data) fn;
  TData result;
  SelectQuery(this.fn, this.result);
}

class QueryObserver<TQueryFnData, TError, TData, TQueryData>
    extends Subscribable<QueryObserverListener> {
  late QueryObserverOptions<TQueryFnData, TError, TData, TQueryData> options;
  QueryClient _client;
  Query<TQueryFnData, TError, TQueryData>? _currentQuery;
  late QueryState<TQueryData, TError> _currentQueryInitialState;
  late QueryObserverResult<TData, TError> _currentResult;
  QueryState<TQueryData, TError>? _currentResultState;
  QueryObserverOptions<TQueryFnData, TError, TData, TQueryData>?
      _currentResultOptions;
  QueryObserverResult<TData, TError>? _previousQueryResult;
  Exception? _previousSelectError;
  SelectQuery? _previousSelect;
  Timer? _staleTimeout;
  Timer? _refetchInterval;
  Duration? _currentRefetchInterval;

  /// List of tracked keys/properties of [QueryObserverResult]
  late List<String> _trackedProps;

  QueryObserver(this._client, options)
      : _trackedProps = [],
        _previousSelectError = null {
    this.setOptions(options);
  }

  bool shouldFetchCurrentQueryOnReconnect() {
    return shouldFetchOnReconnect(_currentQuery!, this.options);
  }

  @override
  void onSubscribe() {
    if (listeners.length == 1) {
      _currentQuery?.addObserver(this);

      if (_currentQuery != null &&
          shouldFetchOnMount(_currentQuery!, options)) {
        _executeFetch();
      }

      _updateTimers();
    }
  }

  @override
  void onUnsubscribe() {
    if (listeners.isEmpty) {
      this.destroy();
    }
  }

  void destroy() {
    listeners = [];
    _clearTimers();
    _currentQuery?.removeObserver(this);
  }

  setOptions(
    QueryObserverOptions<TQueryFnData, TError, TData, TQueryData>? options, [
    NotifyOptions? notifyOptions,
  ]) {
    var prevOptions = this.options;
    var prevQuery = _currentQuery;

    this.options = this._client.defaultQueryObserverOptions(options);

    this.options.queryKey ??= prevOptions.queryKey;

    _updateQuery();

    bool mounted = hasListeners();

    if (mounted &&
        _currentQuery != null &&
        prevQuery != null &&
        shouldFetchOptionally(
            _currentQuery!, prevQuery, this.options, prevOptions)) {
      _executeFetch();
    }
    ;
  }

  QueryObserverResult<TData, TError> getOptimisticResult(
    QueryObserverOptions<TQueryFnData, TError, TData, TQueryData> options,
  ) {
    final defaultedOptions = _client.defaultQueryObserverOptions(options);

    final query = _client.getQueryCache().build(_client, defaultedOptions);

    return createResult(query, defaultedOptions);
  }

  QueryObserverResult<TData, TError> getCurrentResult() {
    return _currentResult;
  }

  /// There's nothing similar to JS [defineProperty] in dart native
  /// objects thus  modifying the underlying property `get` method is
  /// impossible so [trackProp] can't be implemented at the moment
  /// At least not following this procedure
  QueryObserverResult<TData, TError> trackResult(
    QueryObserverResult<TData, TError> result,
    QueryObserverOptions<TQueryFnData, TError, TData, TQueryData>
        defaultedOptions,
  ) {
    // final Map<String, dynamic> trackedResult = <String, dynamic>{};
    // const trackProp = (key: keyof QueryObserverResult) => {
    //   if (!this.trackedProps.includes(key)) {
    //     this.trackedProps.push(key)
    //   }
    // }
    // Object.keys(result).forEach(key => {
    //   Object.defineProperty(trackedResult, key, {
    //     configurable: false,
    //     enumerable: true,
    //     get: () => {
    //       trackProp(key as keyof QueryObserverResult)
    //       return result[key as keyof QueryObserverResult]
    //     },
    //   })
    // })
    // if (defaultedOptions.useErrorBoundary || defaultedOptions.suspense) {
    //   trackProp('error')
    // }
    // return trackedResult

    throw UnimplementedError("COULD NOT IMPLEMENT DUE TO LANGUAGE LIMITATIONS");
  }

  Future<QueryObserverResult<TData, TError>> getNextResult(
    bool? throwOnError,
  ) {
    var completer = Completer<QueryObserverResult<TData, TError>>();
    var unsubscribe;
    unsubscribe = subscribe((result) {
      if (!result.isFetching) {
        unsubscribe?.call();
        if (result.isError && throwOnError == true) {
          if (!completer.isCompleted)
            completer.completeError(result.error as Object);
        } else {
          if (!completer.isCompleted)
            completer.complete(
              result as QueryObserverResult<TData, TError>,
            );
        }
      }
    });
    return completer.future;
  }

  Query<TQueryFnData, TError, TQueryData> getCurrentQuery() {
    return _currentQuery!;
  }

  Future<QueryObserverResult<TData, TError>> fetchOptimistic(
      QueryObserverOptions<TQueryFnData, TError, TData, TQueryData> options) {
    var defaultedOptions = _client.defaultQueryObserverOptions(options);
    var query = _client.getQueryCache().build(_client, defaultedOptions);

    return query.fetch().then((val) {
      return createResult(query, defaultedOptions);
    });
  }

  @protected
  Future<QueryObserverResult<TData, TError>> fetch(
    ObserverFetchOptions fetchOptions,
  ) {
    return _executeFetch(fetchOptions).then((val) {
      updateResult();
      return _currentResult;
    });
  }

  Future<TQueryData?> _executeFetch([ObserverFetchOptions? fetchOptions]) {
    // Make sure we reference the latest query as the current one might have been removed
    _updateQuery();
    // Fetch
    Future<TQueryData?> future = _currentQuery!.fetch(
      this.options,
      fetchOptions,
    );

    if (fetchOptions?.throwOnError != null) {
      future = future.catchError((e) => e);
    }

    return future;
  }

  bool _shouldNotifyListeners(QueryObserverResult<TData, TError> result,
      [QueryObserverResult<TData, TError>? prevResult]) {
    if (prevResult == null) return true;
    if (!options.notifyOnChangeProps &&
        options.notifyOnChangePropsExclusions == null) {
      return true;
    }

    if (options.notifyOnChangeProps == 'tracked' && _trackedProps.isEmpty) {
      return true;
    }

    List<String>? includedProps = options.notifyOnChangeProps == 'tracked'
        ? _trackedProps
        : options.notifyOnChangeProps;

    Map<String, dynamic> resultMap = result.toJson();
    Map<String, dynamic> prevResultMap = prevResult.toJson();

    return resultMap.keys.any((key) {
      var changed = resultMap[key] != prevResultMap[key];
      bool? isIncluded = includedProps?.any((x) => x == key);
      bool isExcluded =
          options.notifyOnChangePropsExclusions?.any((x) => x == key) ?? false;
      return changed &&
          !isExcluded &&
          (includedProps == null || isIncluded == true);
    });
  }

  void updateResult([NotifyOptions? notifyOptions]) {
    QueryObserverResult<TData, TError>? prevResult = _currentResult;

    if (_currentQuery != null)
      _currentResult = this.createResult(_currentQuery!, this.options);
    _currentResultState = _currentQuery?.state;
    _currentResultOptions = this.options;

    // Only notify if something has changed
    if (shallowEqualMap(_currentResult.toJson(), prevResult.toJson())) {
      return;
    }
    NotifyOptions defaultNotifyOptions = NotifyOptions(cache: true);
    if (notifyOptions?.listeners != false &&
        _shouldNotifyListeners(_currentResult, prevResult)) {
      defaultNotifyOptions.listeners = true;
    }

    _notify(NotifyOptions.fromJson({
      ...defaultNotifyOptions.toJson(),
      ...(notifyOptions?.toJson() ?? {}),
    }));
  }

  void _updateQuery() {
    var query = this._client.getQueryCache().build(this._client, this.options);

    if (query == _currentQuery) return;

    var prevQuery = _currentQuery;
    _currentQuery = query;
    _currentQueryInitialState = query.state;
    _previousQueryResult = _currentResult;

    if (hasListeners()) {
      prevQuery?.removeObserver(this);
      query.addObserver(this);
    }
  }

  void onQueryUpdate(Action<TData, TError> action) {
    final NotifyOptions notifyOptions = NotifyOptions();

    if (action.type == 'success') {
      notifyOptions.onSuccess = true;
    } else if (action.type == 'error' && !isCancelledError(action.error)) {
      notifyOptions.onError = true;
    }

    updateResult(notifyOptions);

    if (this.hasListeners()) {
      _updateTimers();
    }
  }

  QueryObserverResult<TData, TError> createResult(
    Query<TQueryFnData, TError, TQueryData> query,
    QueryObserverOptions<TQueryFnData, TError, TData, TQueryData> options,
  ) {
    var prevQuery = _currentQuery;
    var prevOptions = this.options;
    var prevResult = _currentResult;
    var prevResultState = _currentResultState;
    var prevResultOptions = _currentResultOptions;
    bool queryChange = query != prevQuery;
    var queryInitialState =
        queryChange ? query.state : _currentQueryInitialState;
    var prevQueryResult = queryChange ? _currentResult : _previousQueryResult;

    var state = query.state;
    var dataUpdatedAt = state.dataUpdatedAt;
    var error = state.error;
    var errorUpdatedAt = state.errorUpdatedAt;
    var isFetching = state.isFetching;
    var status = state.status;

    bool isPreviousData = false;
    bool isPlaceholderData = false;
    TData? data;

    // Optimistically set result in fetching state if needed
    if (options.optimisticResults == true) {
      var mounted = hasListeners();

      var fetchOnMount = !mounted && shouldFetchOnMount(query, options);

      bool fetchOptionally = mounted &&
          prevQuery != null &&
          shouldFetchOptionally(query, prevQuery, options, prevOptions);

      if (fetchOnMount || fetchOptionally) {
        isFetching = true;
        if (dataUpdatedAt == null) {
          status = QueryStatus.loading;
        }
      }
    }

    // Keep previous data if needed
    if (prevQueryResult != null &&
        options.keepPreviousData == true &&
        state.dataUpdateCount == 0 &&
        prevQueryResult.isSuccess == true &&
        status != QueryStatus.error) {
      data = prevQueryResult.data;
      dataUpdatedAt = prevQueryResult.dataUpdatedAt;
      status = prevQueryResult.status;
      isPreviousData = true;
    }

    // Select data if needed
    else if (options.select != null && state.data != null) {
      if (prevResult != null &&
          state.data == prevResultState?.data &&
          options.select == _previousSelect?.fn &&
          _previousSelectError == null) {
        data = _previousSelect?.result;
      } else {
        try {
          data = options.select?.call(state.data);
          if (options.structuralSharing != false) {
            data = replaceEqualDeep(prevResult?.data, data);
          }
          if (options.select != null && data != null) {
            _previousSelect = SelectQuery<TQueryData, TData>(
              options.select!,
              data,
            );
          }
          _previousSelectError = null;
        } catch (selectError) {
          // getLogger().error(selectError);
          error = selectError as TError;
          _previousSelectError = selectError as Exception;
          errorUpdatedAt = DateTime.now();
          status = QueryStatus.error;
        }
      }
    }
    // Use query data
    else {
      data = state.data as TData;
    }

    if (options.placeholderData != null &&
        data == null &&
        (status == QueryStatus.loading || status == QueryStatus.idle)) {
      var placeholderData;

      if (prevResult?.isPlaceholderData == true &&
          options.placeholderData == prevResultOptions?.placeholderData) {
        placeholderData = prevResult.data;
      } else {
        placeholderData = options.placeholderData;
        if (options.select != null && placeholderData != null) {
          try {
            placeholderData = options.select?.call(placeholderData);
            if (options.structuralSharing != false) {
              placeholderData =
                  replaceEqualDeep(prevResult?.data, placeholderData);
            }
            _previousSelectError = null;
          } catch (selectError) {
            // getLogger().error(selectError);
            error = selectError as TError;
            _previousSelectError = selectError as Exception;
            errorUpdatedAt = DateTime.now();
            status = QueryStatus.error;
          }
        }
      }

      if (placeholderData != null) {
        status = QueryStatus.success;
        data = placeholderData as TData;
        isPlaceholderData = true;
      }
    }

    QueryObserverResult<TData, TError> result = QueryObserverResult(
      status: status,
      dataUpdatedAt: dataUpdatedAt,
      isLoading: status == QueryStatus.loading,
      isSuccess: status == QueryStatus.success,
      isError: status == QueryStatus.error,
      isIdle: status == QueryStatus.idle,
      data: data,
      error: error,
      failureCount: state.fetchFailureCount,
      isFetched: state.dataUpdateCount > 0 || state.errorUpdateCount > 0,
      isFetchedAfterMount:
          state.dataUpdateCount > queryInitialState.dataUpdateCount ||
              state.errorUpdateCount > queryInitialState.errorUpdateCount,
      isFetching: isFetching,
      isRefetching: isFetching && status != QueryStatus.loading,
      isLoadingError:
          status == QueryStatus.error && state.dataUpdatedAt == null,
      isPlaceholderData: isPlaceholderData,
      isPreviousData: isPreviousData,
      isRefetchError: status == 'error' && state.dataUpdatedAt != 0,
      isStale: isStale(query, options),
      refetch: this.refetch,
      remove: this.remove,
    );
    return result;
  }

  void _notify(NotifyOptions notifyOptions) {
    notifyManager.batch(() {
      // First trigger the configuration callbacks
      if (notifyOptions.onSuccess == true) {
        this.options.onSuccess?.call(_currentResult.data!);
        this.options.onSettled?.call(_currentResult.data!);
      } else if (notifyOptions.onError == true) {
        this.options.onError?.call(_currentResult.error!);
        this.options.onSettled?.call(null, _currentResult.error!);
      }

      // Then trigger the listeners
      if (notifyOptions.listeners == true) {
        this.listeners.forEach((listener) {
          listener(_currentResult);
        });
      }

      // Then the cache listeners
      if (notifyOptions.cache == true && _currentQuery != null) {
        _client.getQueryCache().notify(
              QueryCacheNotifyEvent(
                QueryCacheNotifyEventType.observerResultsUpdated,
                _currentQuery as Query,
              ),
            );
      }
    });
  }

  Duration? _computeRefetchInterval() {
    return this.options.refetchInterval != null && _currentQuery != null
        ? this.options.refetchInterval!(_currentResult.data, _currentQuery!)
        : null;
  }

  void _updateTimers() {
    _updateStaleTimeout();
    _updateRefetchInterval(_computeRefetchInterval());
  }

  void _updateStaleTimeout() {
    _clearStaleTimeout();
    if (_currentResult.isStale ||
        options.staleTime == null ||
        _currentResult.dataUpdatedAt == null) return;

    // The timeout is sometimes triggered 1 ms before the stale time
    // expiration. To mitigate this issue we always add 1 ms to the
    // timeout.
    Duration time = Duration(
      milliseconds:
          timeUntilStale(_currentResult.dataUpdatedAt!, this.options.staleTime)
                  .inMilliseconds +
              1,
    );

    _staleTimeout = Timer(time, () {
      if (!_currentResult.isStale) {
        this.updateResult();
      }
    });
  }

  _updateRefetchInterval(Duration? nextInterval) {
    _clearRefetchInterval();

    _currentRefetchInterval = nextInterval;

    if (this.options.enabled == false ||
        _currentRefetchInterval == null ||
        _currentRefetchInterval == Duration.zero) return;

    _refetchInterval = Timer.periodic(_currentRefetchInterval!, (t) {
      if (this.options.refetchIntervalInBackground == true) {
        _executeFetch();
      }
    });
  }

  void _clearTimers() {
    _clearStaleTimeout();
    _clearRefetchInterval();
  }

  void _clearStaleTimeout() {
    _staleTimeout?.cancel();
    _staleTimeout = null;
  }

  void _clearRefetchInterval() {
    _refetchInterval?.cancel();
    _refetchInterval = null;
  }

  void remove() {
    _client.getQueryCache().remove(_currentQuery as Query);
    _clearTimers();
    _currentQuery?.removeObserver(this);
  }

  Future<QueryObserverResult<TData, TError>> refetch<TPageData>({
    RefetchableQueryFilters<TPageData>? filters,
    RefetchOptions? options,
  }) {
    return fetch(
      ObserverFetchOptions(
        cancelRefetch: options?.cancelRefetch,
        meta: filters?.toJson(),
        throwOnError: options?.throwOnError,
      ),
    );
  }
}

bool shouldLoadOnMount<TQueryFnData, TError, TData, TQueryData>(
  Query<TQueryFnData, TError, TQueryData> query,
  QueryObserverOptions<TQueryFnData, TError, TData, TQueryData> options,
) {
  return (options.enabled != false &&
      query.state.dataUpdatedAt != null &&
      !(query.state.status == QueryStatus.error &&
          options.retryOnMount == false));
}

bool shouldRefetchOnMount<TQueryFnData, TError, TData, TQueryData>(
  Query<TQueryFnData, TError, TQueryData> query,
  QueryObserverOptions<TQueryFnData, TError, TData, TQueryData> options,
) {
  return (options.enabled != false &&
      query.state.dataUpdatedAt != null &&
      (options.refetchOnMount == RefetchOnMount.always ||
          (options.refetchOnMount != RefetchOnMount.off &&
              isStale(query, options))));
}

bool shouldFetchOnMount<TQueryFnData, TError, TData, TQueryData>(
  Query<TQueryFnData, TError, TQueryData> query,
  QueryObserverOptions<TQueryFnData, TError, TData, TQueryData> options,
) {
  return (shouldLoadOnMount(query, options) ||
      shouldRefetchOnMount(query, options));
}

bool shouldFetchOnReconnect<TQueryFnData, TError, TData, TQueryData>(
  Query<TQueryFnData, TError, TQueryData> query,
  QueryObserverOptions<TQueryFnData, TError, TData, TQueryData> options,
) {
  return (options.enabled != false &&
      (options.refetchOnReconnect == RefetchOnReconnect.always ||
          (options.refetchOnReconnect != RefetchOnReconnect.off &&
              isStale(query, options))));
}

bool shouldFetchOptionally<TQueryFnData, TError, TData, TQueryData>(
  Query<TQueryFnData, TError, TQueryData> query,
  Query<TQueryFnData, TError, TQueryData> prevQuery,
  QueryObserverOptions<TQueryFnData, TError, TData, TQueryData> options,
  QueryObserverOptions<TQueryFnData, TError, TData, TQueryData> prevOptions,
) {
  return (options.enabled != false &&
      (query != prevQuery || prevOptions.enabled == false) &&
      (options.suspense != true || query.state.status != QueryStatus.error) &&
      isStale(query, options));
}

bool isStale<TQueryFnData, TError, TData, TQueryData>(
  Query<TQueryFnData, TError, TQueryData> query,
  QueryObserverOptions<TQueryFnData, TError, TData, TQueryData> options,
) {
  return query.isStaleByTime(options.staleTime);
}
