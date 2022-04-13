import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:fl_query/src/core/models.dart';
import 'package:fl_query/src/core/notify_manager.dart';
import 'package:fl_query/src/core/query_cache.dart';
import 'package:fl_query/src/core/query_key.dart';
import 'package:fl_query/src/core/query_observer.dart';
import 'package:fl_query/src/core/retryer.dart';
import 'package:fl_query/src/core/utils.dart';
import 'package:meta/meta.dart';
import 'package:collection/collection.dart';

class FetchOptions {
  bool? cancelRefetch;
  dynamic meta;
  FetchOptions({this.cancelRefetch, this.meta});
}

class FetchContext<TQueryFnData extends Map<String, dynamic>, TError,
    TData extends Map<String, dynamic>> {
  FutureOr<TQueryFnData> Function() fetchFn;
  FetchOptions? fetchOptions;
  QueryOptions<TQueryFnData, TError, TData> options;
  QueryKey queryKey;
  QueryState<TData, TError> state;
  QueryMeta? meta;

  FetchContext({
    required this.fetchFn,
    required this.options,
    required this.queryKey,
    required this.state,
    this.meta,
    this.fetchOptions,
  });
}

class QueryBehavior<TQueryFnData extends Map<String, dynamic>, TError,
    TData extends Map<String, dynamic>> {
  void Function(FetchContext<TQueryFnData, TError, TData> context) onFetch;
  QueryBehavior({required this.onFetch});
}

class QueryState<TData extends Map<String, dynamic>, TError> {
  TData? data;
  TError? error;
  QueryStatus status;
  DateTime? dataUpdatedAt;
  int dataUpdateCount;
  DateTime? errorUpdatedAt;
  int errorUpdateCount;
  int fetchFailureCount;
  dynamic fetchMeta;
  bool isFetching;
  bool isInvalidated;
  bool isPaused;

  QueryState({
    required this.status,
    required this.dataUpdatedAt,
    required this.dataUpdateCount,
    required this.errorUpdatedAt,
    required this.errorUpdateCount,
    required this.fetchFailureCount,
    required this.fetchMeta,
    required this.isFetching,
    required this.isInvalidated,
    required this.isPaused,
    this.data,
    this.error,
  });

  QueryState.fromJson(Map<String, dynamic> json)
      : data = json["data"],
        error = json["error"],
        status = json["status"],
        dataUpdatedAt = json["dataUpdatedAt"],
        dataUpdateCount = json["dataUpdateCount"],
        errorUpdatedAt = json["errorUpdatedAt"],
        errorUpdateCount = json["errorUpdateCount"],
        fetchFailureCount = json["fetchFailureCount"],
        fetchMeta = json["fetchMeta"],
        isFetching = json["isFetching"],
        isInvalidated = json["isInvalidated"],
        isPaused = json["isPaused"];

  Map<String, dynamic> toJson() {
    return {
      "data": data,
      "error": error,
      "status": status,
      "dataUpdatedAt": dataUpdatedAt,
      "dataUpdateCount": dataUpdateCount,
      "errorUpdatedAt": errorUpdatedAt,
      "errorUpdateCount": errorUpdateCount,
      "fetchFailureCount": fetchFailureCount,
      "fetchMeta": fetchMeta,
      "isFetching": isFetching,
      "isInvalidated": isInvalidated,
      "isPaused": isPaused,
    };
  }
}

enum ActionType {
  failed,
  fetch,
  success,
  error,
  invalidate,
  pause,
  resume,
  setState,
}

class SetStateOptions {
  Object? meta;
  SetStateOptions({this.meta});
  Map<String, dynamic> toJson() {
    return {"meta": meta};
  }
}

class Action<TData extends Map<String, dynamic>, TError> {
  ActionType type;
  Object? meta;
  TData? data;
  DateTime? dataUpdatedAt;
  TError? error;
  QueryState<TData, TError>? state;
  SetStateOptions? setStateOptions;

  Action(
    this.type, {
    this.meta,
    this.data,
    this.dataUpdatedAt,
    this.error,
    this.state,
    this.setStateOptions,
  }) {
    if (type == ActionType.error && error == null)
      throw Exception(
          "[Action.Action] property `error` can't be null when `type` = `$type`");

    if (type == ActionType.setState && state == null)
      throw Exception(
          "[Action.Action] property `state` can't be null when `type` = `$type`");
  }

  Map<String, dynamic> toJson() {
    return {
      "type": type,
      "meta": meta,
      "data": data,
      "dataUpdatedAt": dataUpdatedAt,
      "error": error,
      "state": state,
      "setStateOptions": setStateOptions,
    };
  }
}

class Query<TQueryFnData extends Map<String, dynamic>, TError,
    TData extends Map<String, dynamic>> {
  QueryKey queryKey;
  String queryHash;
  late QueryOptions<TQueryFnData, TError, TData> options;
  late QueryState<TData, TError> initialState;
  QueryState<TData, TError>? revertState;
  late QueryState<TData, TError> state;
  Duration? cacheTime;
  QueryMeta? meta;

  QueryCache _cache;
  // Future<TData>? _future;
  Completer<TData>? _completer;
  Timer? _gcTimeout;
  Retryer<TData, TError>? _retryer;
  List<QueryObserver> _observers;
  QueryOptions<TQueryFnData, TError, TData>? _defaultOptions;
  bool _abortSignalConsumed;
  bool _hadObservers;

  Query({
    required this.queryKey,
    required this.queryHash,
    required QueryCache cache,
    QueryOptions<TQueryFnData, TError, TData>? options,
    QueryOptions<TQueryFnData, TError, TData>? defaultOptions,
    QueryState<TData, TError>? state,
    QueryMeta? meta,
  })  : _abortSignalConsumed = false,
        _hadObservers = false,
        _defaultOptions = defaultOptions,
        _observers = [],
        _cache = cache {
    _setOptions(options);
    initialState = state ?? _getDefaultState(this.options);
    this.state = initialState;
    this.meta = meta;
    _scheduleGc();
  }

  void _scheduleGc() {
    this._clearGcTimeout();
    if (this.cacheTime != null) {
      _gcTimeout = Timer(cacheTime!, () {
        this._optionalRemove();
      });
    }
  }

  void _clearGcTimeout() {
    _gcTimeout?.cancel();
    _gcTimeout = null;
  }

  void _optionalRemove() {
    if (_observers.isEmpty) {
      if (state.isFetching) {
        if (_hadObservers) {
          _scheduleGc();
        }
      } else {
        _cache.remove(this);
      }
    }
  }

  void _setOptions(QueryOptions<TQueryFnData, TError, TData>? options) {
    this.options = QueryOptions.fromJson({
      ...(_defaultOptions?.toJson() ?? {}),
      ...(options?.toJson() ?? {}),
    });
    meta = options?.meta;

    /// Default to [5 minutes] if cache time isn't set
    cacheTime = Duration(
        milliseconds: max(
      cacheTime?.inMilliseconds ?? 0,
      this.options.cacheTime?.inMilliseconds ?? 5 * 60 * 1000,
    ));
  }

  QueryState<TData, TError> _getDefaultState(
      QueryOptions<TQueryFnData, TError, TData> options) {
    var data = options.initialData;
    bool hasData = data != null;

    DateTime? initialDataUpdatedAt =
        hasData ? options.initialDataUpdatedAt : null;

    return QueryState(
      data: data,
      dataUpdateCount: 0,
      dataUpdatedAt: hasData ? initialDataUpdatedAt ?? DateTime.now() : null,
      error: null,
      errorUpdateCount: 0,
      errorUpdatedAt: null,
      fetchFailureCount: 0,
      fetchMeta: null,
      isFetching: false,
      isInvalidated: false,
      isPaused: false,
      status: hasData ? QueryStatus.success : QueryStatus.idle,
    );
  }

  TData setData(
    DataUpdateFunction<TData?, TData> updater, {
    DateTime? updatedAt,
  }) {
    try {
      var prevData = this.state.data;
      var data = updater(prevData);
      // Use prev data if an isDataEqual function is defined and returns `true`
      if (this.options.isDataEqual?.call(prevData, data) == true) {
        data = prevData as TData;
      } else if (this.options.structuralSharing != false) {
        // Structurally share data between prev and new data if needed
        final merged =
            Map<String, dynamic>.from(replaceEqualDeep(prevData, data));
        data = merged as TData;
      }
      // Set data and mark it as cached
      _dispatch(Action(
        ActionType.success,
        data: data,
        dataUpdatedAt: updatedAt,
      ));
      return data;
    } catch (e, stack) {
      print("[Query.setData] $e");
      print(stack);
      rethrow;
    }
  }

  void setState(
    QueryState<TData, TError> state, [
    SetStateOptions? setStateOptions,
  ]) {
    _dispatch(Action(
      ActionType.setState,
      state: state,
      setStateOptions: setStateOptions,
    ));
  }

  Future<void> cancel({bool? revert, bool? silent}) {
    // var future = _future;
    _retryer?.cancel(revert: revert, silent: silent);
    if (_completer != null && !_completer!.isCompleted) {
      _completer!.completeError("Cancelled Job", StackTrace.current);
      return _completer!.future.then(noop).catchError(noop);
    }
    return Future.value();
  }

  void reset() {
    destroy();
    setState(initialState);
  }

  destroy() {
    _clearGcTimeout();
    cancel(silent: true);
  }

  bool isActive() {
    return _observers.any((observer) => observer.options.enabled != false);
  }

  bool isFetching() {
    return this.state.isFetching;
  }

  Future<TData> fetch([
    QueryOptions<TQueryFnData, TError, TData>? options,
    ObserverFetchOptions? fetchOptions,
  ]) {
    if (this.state.isFetching) {
      if (this.state.dataUpdatedAt != null &&
          fetchOptions?.cancelRefetch == true) {
        // Silently cancel current fetch if the user wants to cancel re-fetches
        this.cancel(silent: true);
      } else if (_completer != null) {
        // make sure that retries that were potentially cancelled due to unmounts can continue
        _retryer?.continueRetry();
        // Return current promise if we are already fetching
        return _completer!.future;
      }
    }

    // Update config if passed, otherwise the config from the last execution is used
    if (options != null) {
      _setOptions(options);
    }

    // Use the options from the first observer with a query function if no function is found.
    // This can happen when the query is hydrated or created with setQueryData.
    if (this.options.queryFn == null) {
      final observer =
          _observers.firstWhereOrNull((x) => x.options.queryFn != null);
      if (observer != null) {
        _setOptions(QueryOptions<TQueryFnData, TError, TData>(
          queryKey: observer.options.queryKey,
          queryKeyHashFn: observer.options.queryKeyHashFn,
          cacheTime: observer.options.cacheTime,
          isDataEqual: observer.options.isDataEqual,
          queryFn:
              observer.options.queryFn as QueryFunction<TQueryFnData, dynamic>,
          queryHash: observer.options.queryHash,
          initialData: observer.options.initialData as TData?,
          initialDataUpdatedAt: observer.options.initialDataUpdatedAt,
          meta: observer.options.meta,
          structuralSharing: observer.options.structuralSharing,
          defaulted: observer.options.defaulted,
        ));
      }
    }

    QueryFunctionContext queryFnContext = QueryFunctionContext(
      queryKey: queryKey,
      meta: meta,
    );

    /// !!LANGUAGE LIMITATION!! There's no equivalent of [AbortController]
    /// the [get] can be implemented using Dart's getter but it'd be
    /// useless since there's no equivalent of AbortController.
    /// Have to find a better way to control ABORTION

    // Object.defineProperty(queryFnContext, 'signal', {
    //   enumerable: true,
    //   get: () {
    //     if (abortController) {
    //       this.abortSignalConsumed = true
    //       return abortController.signal
    //     }
    //     return undefined
    //   },
    // })

    // Create fetch function
    FutureOr<TQueryFnData> fetchFn() {
      if (this.options.queryFn == null) {
        return Future.error('Missing queryFn');
      }
      _abortSignalConsumed = false;
      return options!.queryFn!.call(queryFnContext);
    }

    // Trigger behavior hook
    FetchContext<TQueryFnData, TError, TData> context =
        FetchContext<TQueryFnData, TError, TData>(
      fetchOptions: fetchOptions,
      options: this.options,
      queryKey: queryKey,
      state: this.state,
      fetchFn: fetchFn,
      meta: this.meta,
    );

    this.options.behavior?.onFetch(context);
    // Store state in case the current fetch needs to be reverted
    this.revertState = this.state;

    // Set to fetching state if not already in it
    if (!this.state.isFetching ||
        this.state.fetchMeta != context.fetchOptions?.meta) {
      _dispatch(Action(ActionType.fetch, meta: context.fetchOptions?.meta));
    }

    _retryer = Retryer(
      fn: context.fetchFn as FutureOr<TData> Function(),
      // abort: abortController?.abort?.bind(abortController),
      onSuccess: (data) {
        this.setData((_) => data);

        // Notify cache callback
        _cache.onData?.call(data, this);
        if (_completer?.isCompleted == false) _completer?.complete(data);
        // Remove query after fetching if cache time is 0
        if (this.cacheTime == null || this.cacheTime == Duration.zero) {
          _optionalRemove();
        }
      },
      onError: (TError error) {
        // Optimistically update state if needed
        if (!(isCancelledError(error) && (error as dynamic)?.silent == true)) {
          _dispatch(Action(ActionType.error, error: error));
        }

        if (!isCancelledError(error)) {
          // Notify cache callback
          _cache.onError?.call(error, this);

          // Log error
          // getLogger().error(error);
        }

        // Remove query after fetching if cache time is 0
        if (this.cacheTime == null || this.cacheTime == Duration.zero) {
          _optionalRemove();
        }
        if (_completer?.isCompleted == false)
          _completer?.completeError(
              error ?? "Retry Failed", StackTrace.current);
      },
      onFail: (failureCount, error) {
        _dispatch(Action(ActionType.failed));
      },
      onPause: () {
        _dispatch(Action(ActionType.pause));
      },
      onContinue: () {
        _dispatch(Action(ActionType.resume));
      },
      retry: context.options.retry,
      retryDelay: context.options.retryDelay,
    );

    this._completer = _retryer!.completer;
    return this._completer!.future;
  }

  void _dispatch(Action<TData, TError> action) {
    this.state = this.reducer(this.state, action);

    notifyManager.batch(() {
      _observers.forEach((observer) {
        observer.onQueryUpdate(action);
      });
      _cache.notify(QueryCacheNotifyEvent(
        QueryCacheNotifyEventType.queryUpdated,
        this,
        action: action,
      ));
    });
  }

  void addObserver(QueryObserver observer) {
    if (_observers.indexOf(observer) == -1) {
      _observers.add(observer);
      _hadObservers = true;

      // Stop the query from being garbage collected
      _clearGcTimeout();

      _cache.notify(QueryCacheNotifyEvent(
        QueryCacheNotifyEventType.observerAdded,
        this,
        observer: observer,
      ));
    }
  }

  void removeObserver(QueryObserver observer) {
    if (_observers.indexOf(observer) != -1) {
      _observers = _observers.where((x) => x != observer).toList();

      if (_observers.isEmpty) {
        // If the transport layer does not support cancellation
        // we'll let the query continue so the result can be cached
        if (_retryer != null) {
          if (_retryer?.isTransportCancelable == true || _abortSignalConsumed) {
            _retryer?.cancel(revert: true);
          } else {
            _retryer?.cancelRetry();
          }
        }

        if (cacheTime != null) {
          _scheduleGc();
        } else {
          _cache.remove(this);
        }
      }

      _cache.notify(QueryCacheNotifyEvent(
        QueryCacheNotifyEventType.observerRemoved,
        this,
        observer: observer,
      ));
    }
  }

  int getObserversCount() {
    return _observers.length;
  }

  void invalidate() {
    if (!this.state.isInvalidated) {
      _dispatch(Action(ActionType.invalidate));
    }
  }

  bool isStale() {
    return (this.state.isInvalidated ||
        this.state.dataUpdatedAt == null ||
        _observers
            .any((observer) => observer.getCurrentResult()?.isStale == true));
  }

  bool isStaleByTime(Duration? staleTime) {
    return (this.state.isInvalidated ||
        this.state.dataUpdatedAt == null ||
        timeUntilStale(this.state.dataUpdatedAt!, staleTime) == Duration.zero);
  }

  void onOnline() {
    var observer = _observers
        .firstWhereOrNull((x) => x.shouldFetchCurrentQueryOnReconnect());

    if (observer != null) {
      observer.refetch();
    }

    // Continue fetch if currently paused
    _retryer?.continueFn();
  }

  @protected
  QueryState<TData, TError> reducer(
    QueryState<TData, TError> state,
    Action<TData, TError> action,
  ) {
    switch (action.type) {
      case ActionType.failed:
        return QueryState.fromJson({
          ...state.toJson(),
          "fetchFailureCount": state.fetchFailureCount + 1,
        });
      case ActionType.fetch:
        return QueryState.fromJson({
          ...state.toJson(),
          "fetchFailureCount": 0,
          "fetchMeta": action.meta,
          "isFetching": true,
          "isPaused": false,
          if (state.dataUpdatedAt == null)
            ...({
              "error": null,
              "status": QueryStatus.loading,
            })
        });
      case ActionType.success:
        return QueryState.fromJson({
          ...state.toJson(),
          "data": action.data,
          "dataUpdateCount": state.dataUpdateCount + 1,
          "dataUpdatedAt": action.dataUpdatedAt ?? DateTime.now(),
          "error": null,
          "fetchFailureCount": 0,
          "isFetching": false,
          "isInvalidated": false,
          "isPaused": false,
          "status": QueryStatus.success,
        });
      case ActionType.error:
        var error = action.error as dynamic;
        if (isCancelledError(error) &&
            error?.revert == true &&
            revertState != null) {
          return QueryState.fromJson(revertState!.toJson());
        }

        return QueryState.fromJson({
          ...state.toJson(),
          "error": error as TError,
          "errorUpdateCount": state.errorUpdateCount + 1,
          "errorUpdatedAt": DateTime.now(),
          "fetchFailureCount": state.fetchFailureCount + 1,
          "isFetching": false,
          "isPaused": false,
          "status": QueryStatus.error,
        });
      case ActionType.invalidate:
        return QueryState.fromJson({
          ...state.toJson(),
          "isInvalidated": true,
        });
      case ActionType.pause:
        return QueryState.fromJson({
          ...state.toJson(),
          "isPaused": true,
        });
      case ActionType.resume:
        return QueryState.fromJson({
          ...state.toJson(),
          "isPaused": false,
        });
      case ActionType.setState:
        return QueryState.fromJson({
          ...state.toJson(),
          ...(action.state?.toJson() ?? {}),
        });
      default:
        return state;
    }
  }
}
