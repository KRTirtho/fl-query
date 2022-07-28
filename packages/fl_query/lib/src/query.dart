import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fl_query/src/base_operation.dart';
import 'package:fl_query/src/models/query_job.dart';
import 'package:fl_query/src/utils.dart';
import 'package:flutter/widgets.dart';

enum QueryStatus {
  /// in times when an error occurs
  /// will get reset to idle on refetch/retry
  error,

  /// when a query successfully executes
  success,

  /// when the query is running (not refetching)
  loading,

  /// when the query isn't yet fetched, re-fetched, or got reset
  /// mostly when both [data] & [error] are null. Also [fetched] is false
  idle,

  /// when the query is refetching (rerunning)
  refetching;
}

typedef QueryTaskFunction<T extends Object, Outside> = FutureOr<T> Function(
  String queryKey,
  Outside externalData,
);

typedef QueryListener<T> = FutureOr<void> Function(T);

typedef ListenerUnsubscriber = void Function();

typedef QueryUpdateFunction<T> = FutureOr<T> Function(T? oldData);

class Query<T extends Object, Outside> extends BaseOperation<T> {
  // all params
  final String queryKey;
  QueryTaskFunction<T, Outside> task;

  bool? refetchOnMount;
  bool? refetchOnReconnect;

  final T? _initialData;

  // got from global options
  Duration _staleTime;

  /// total count of how many times the query retried to get a successful
  /// result
  int refetchCount = 0;
  bool enabled;

  QueryStatus status;

  final Set<QueryListener<T>> _onDataListeners = Set<QueryListener<T>>();
  final Set<QueryListener<dynamic>> _onErrorListeners =
      Set<QueryListener<dynamic>>();

  // externalData will always be passed to the task Callback
  // it will change based on the presence of QueryBuilder
  Outside _externalData;

  Outside? _prevUsedExternalData;

  Duration? refetchInterval;

  Timer? _refetchIntervalTimer;

  Connectivity _connectivity;

  Query({
    required this.queryKey,
    required this.task,
    required Duration staleTime,
    required super.cacheTime,
    required Outside externalData,
    required super.retries,
    required super.retryDelay,
    required super.queryBowl,
    this.refetchOnMount,
    this.refetchOnReconnect,
    this.refetchInterval,
    this.enabled = true,
    Connectivity? connectivity,
    T? initialData,
    QueryListener<T>? onData,
    QueryListener<dynamic>? onError,
  })  : _staleTime = staleTime,
        _initialData = initialData,
        _externalData = externalData,
        status = QueryStatus.idle,
        _connectivity = connectivity ?? Connectivity(),
        super(data: initialData) {
    if (onData != null) _onDataListeners.add(onData);
    if (onError != null) _onErrorListeners.add(onError);

    if (refetchInterval != null && refetchInterval != Duration.zero) {
      _refetchIntervalTimer = _createRefetchTimer();
    }
  }

  Query.fromOptions(
    QueryJob<T, Outside> options, {
    required super.queryBowl,
    required Outside externalData,
    QueryListener<T>? onData,
    QueryListener<dynamic>? onError,
  })  : queryKey = options.queryKey,
        enabled = options.enabled ?? true,
        task = options.task,
        _staleTime = options.staleTime ?? const Duration(milliseconds: 500),
        _initialData = options.initialData,
        _externalData = externalData,
        refetchInterval = options.refetchInterval,
        refetchOnMount = options.refetchOnMount,
        refetchOnReconnect = options.refetchOnReconnect,
        status = QueryStatus.idle,
        _connectivity = options.connectivity ?? Connectivity(),
        super(
          cacheTime: options.cacheTime ?? const Duration(minutes: 5),
          retries: options.retries ?? 3,
          retryDelay: options.retryDelay ?? const Duration(milliseconds: 200),
          data: options.initialData,
        ) {
    if (onData != null) _onDataListeners.add(onData);
    if (onError != null) _onErrorListeners.add(onError);
    if (refetchInterval != null && refetchInterval != Duration.zero) {
      _refetchIntervalTimer = _createRefetchTimer();
    }
  }

  // all getters & setters

  Outside get externalData => _externalData;
  Outside? get prevUsedExternalData => _prevUsedExternalData;

  Timer _createRefetchTimer() {
    return Timer.periodic(
      refetchInterval!,
      (_) async {
        // only refetch if its connected to the internet or refetch will
        // always result in error while there's no internet
        if (isStale && await isInternetConnected()) await refetch();
      },
    );
  }

  /// Calls the task function & doesn't check if there's already
  /// cached data available
  Future<void> _execute() async {
    try {
      retryAttempts = 0;
      data = await task(
        queryKey,
        _externalData,
      );
      _prevUsedExternalData = _externalData;
      updatedAt = DateTime.now();
      status = QueryStatus.success;
      for (final onData in _onDataListeners) {
        onData(data!);
      }
      notifyListeners();
    } catch (e) {
      if (retries == 0) {
        status = QueryStatus.error;
        error = e;
        for (final onError in _onErrorListeners) {
          onError(error);
        }
        notifyListeners();
      } else {
        // retrying for retry count if failed for the first time
        while (retryAttempts <= retries) {
          await Future.delayed(retryDelay);
          try {
            data = await task(
              queryKey,
              _externalData,
            );
            _prevUsedExternalData = _externalData;
            status = QueryStatus.success;
            for (final onData in _onDataListeners) {
              await onData(data!);
            }
            notifyListeners();
            break;
          } catch (e) {
            if (retryAttempts == retries) {
              status = QueryStatus.error;
              error = e;
              for (final onError in _onErrorListeners) {
                await onError(error);
              }
              notifyListeners();
              break;
            }
            retryAttempts++;
          }
        }
      }
    }
  }

  void addDataListener(QueryListener<T> listener) {
    _onDataListeners.add(listener);
  }

  void addErrorListener(QueryListener<dynamic> listener) {
    _onErrorListeners.add(listener);
  }

  void removeDataListener(QueryListener<T> listener) {
    _onDataListeners.remove(listener);
  }

  void removeErrorListener(QueryListener<dynamic> listener) {
    _onErrorListeners.remove(listener);
  }

  Future<T?> fetch() async {
    if (!enabled) return null;

    /// if isLoading/isRefetching is true that means its already fetching/
    /// refetching. So [_execute] again can create a race condition
    if (isLoading || isRefetching || hasData) return data;
    status = QueryStatus.loading;
    notifyListeners();
    return _execute().then((_) {
      fetched = true;
      return data;
    });
  }

  Future<T?> refetch() async {
    /// if isLoading/isRefetching is true that means its already fetching/
    /// refetching. So [_execute] again can create a race condition
    if (isRefetching || isLoading) return data;
    if (enabled && !fetched) return await fetch();
    status = QueryStatus.refetching;
    refetchCount++;
    // disabling the lazy query bound when query was actually called
    if (!enabled) enabled = true;
    notifyListeners();
    return await _execute().then((_) => data);
  }

  /// can be used to update the data manually. Can be useful when used
  /// together with mutations to perform optimistic updates or manual data
  /// updates
  /// For updating particular queries after a mutation using the
  /// `QueryBowl.refetchQueries` is more appropriate. But this one can be
  /// used when only 1 query needs get updated
  ///
  /// Every time a new instance of data should be returned because of
  /// immutability
  void setQueryData(QueryUpdateFunction<T> updateFn) async {
    final newData = await updateFn(data);
    if (data == newData) return;
    data = newData;
    status = QueryStatus.success;
    notifyListeners();
  }

  void setExternalData(Outside externalData) {
    _prevUsedExternalData = _externalData;
    _externalData = externalData;
  }

  void reset() {
    refetchCount = 0;
    data = _initialData;
    error = null;
    fetched = false;
    status = QueryStatus.idle;
    retryAttempts = 0;
    _onDataListeners.clear();
    _onErrorListeners.clear();
    mounts.clear();
  }

  /// Update configurations of the query after already creating the Query
  /// instance
  void updateDefaultOptions({
    Duration? refetchInterval,
    Duration? staleTime,
    Duration? cacheTime,
    bool? refetchOnMount,
    bool? refetchOnReconnect,
  }) {
    if (this.refetchInterval == null &&
        refetchInterval != null &&
        refetchInterval != Duration.zero) {
      this.refetchInterval = refetchInterval;
      _refetchIntervalTimer?.cancel();
      _refetchIntervalTimer = _createRefetchTimer();
    }
    if (this.cacheTime == Duration(minutes: 5) && cacheTime != null)
      this.cacheTime = cacheTime;
    if (this._staleTime == const Duration(milliseconds: 500) &&
        staleTime != null) this._staleTime = staleTime;
    if (this.refetchOnMount == null && refetchOnMount != null)
      this.refetchOnMount = refetchOnMount;
    if (this.refetchOnReconnect == null && refetchOnReconnect != null)
      this.refetchOnReconnect = refetchOnReconnect;
    notifyListeners();
  }

  Future<bool> isInternetConnected() async {
    return isConnectedToInternet(await _connectivity.checkConnectivity());
  }

  /// invalidates the query
  void invalidate() {
    /// subtracting [staleTime] from [updatedAt] as staleTime=Duration.zero
    /// indicates the query must never become stale but subtracting the
    /// [staleTime] will always revert the updatedAt time to the default
    /// time whenever isStale is called
    updatedAt = updatedAt.subtract(_staleTime);
    notifyListeners();
  }

  bool get isStale {
    /// when [_staleTime] is [Duration.zero], the query will always be
    /// stale & will never refetch in the background. But can be inactive
    /// if [mounts.length] become zero
    if (_staleTime == Duration.zero) return false;

    // when [DateTime.now()] is after [update_at + stale_time] it means
    // the data has become stale
    return DateTime.now().isAfter(updatedAt.add(_staleTime));
  }

  bool get isError => status == QueryStatus.error;
  bool get isIdle => status == QueryStatus.idle;
  bool get isLoading => status == QueryStatus.loading;
  bool get isRefetching => status == QueryStatus.refetching;
  bool get isSuccess => status == QueryStatus.success;

  A? cast<A>() => this is A ? this as A : null;

  String get debugLabel => "Query($queryKey)";

  @override
  void mount(ValueKey<String> uKey) {
    super.mount(uKey);
    if (refetchOnMount == true && isStale) {
      this.isInternetConnected().then((isConnected) async {
        if (isConnected) await refetch();
      });
    }
  }

  @override
  String toString() {
    return debugLabel;
  }

  @override
  bool operator ==(other) {
    return (other is Query<T, Outside> && other.queryKey == queryKey) ||
        identical(other, this);
  }
}
