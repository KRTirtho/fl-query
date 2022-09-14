import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fl_query/src/base_operation.dart';
import 'package:fl_query/src/mixins/autocast.dart';
import 'package:fl_query/src/query.dart';
import 'package:fl_query/src/utils.dart';
import 'package:flutter/widgets.dart';

abstract class BaseQuery<T extends Object, Outside, Error>
    extends BaseOperation<T, Error> with AutoCast {
// all params
  final String queryKey;
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

  final Set _onDataListeners = Set();
  final Set _onErrorListeners = Set();

  // externalData will always be passed to the task Callback
  // it will change based on the presence of QueryBuilder
  Outside _externalData;

  Outside? _prevUsedExternalData;

  Duration? refetchInterval;

  Timer? _refetchIntervalTimer;

  Connectivity _connectivity;

  T? _previousData;

  BaseQuery({
    required this.queryKey,
    required Duration staleTime,
    required super.cacheTime,
    required Outside externalData,
    required super.retries,
    required super.retryDelay,
    required super.queryBowl,
    required this.status,
    this.refetchOnMount,
    this.refetchOnReconnect,
    this.refetchInterval,
    this.enabled = true,
    T? previousData,
    Connectivity? connectivity,
    T? initialData,
    onData,
    onError,
  })  : _staleTime = staleTime,
        _initialData = initialData,
        _externalData = externalData,
        _connectivity = connectivity ?? Connectivity(),
        _previousData = previousData,
        super(data: previousData ?? initialData) {
    if (onData != null) _onDataListeners.add(onData);
    if (onError != null) _onErrorListeners.add(onError);

    if (refetchInterval != null && refetchInterval != Duration.zero) {
      _refetchIntervalTimer = createRefetchTimer();
    }
  }
  // all getters & setters

  Outside get externalData => _externalData;
  Outside? get prevUsedExternalData => _prevUsedExternalData;

  @protected
  Timer createRefetchTimer();

  /// Calls the task function & doesn't check if there's already
  /// cached data available
  @protected
  Future<void> execute() async {
    try {
      retryAttempts = 0;
      await setData();
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
        setError(e);
        for (final onError in _onErrorListeners) {
          onError(error);
        }
        notifyListeners();
      } else {
        // retrying for retry count if failed for the first time
        while (retryAttempts <= retries) {
          await Future.delayed(retryDelay);
          try {
            await setData();
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
              setError(e);
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

  void addDataListener(listener) {
    _onDataListeners.add(listener);
  }

  void addErrorListener(listener) {
    _onErrorListeners.add(listener);
  }

  void removeDataListener(listener) {
    _onDataListeners.remove(listener);
  }

  void removeErrorListener(listener) {
    _onErrorListeners.remove(listener);
  }

  /// fetches data or runs the provided task initially
  ///
  /// Once [data] is available it won't run the [task] ever again
  /// and will only return the available data
  ///
  /// If a [fetch] is already running in the background it'll just return
  /// the current available [data] (which can be nul if no [initialPage]
  /// was provided) instead of running the task to prevent race conditions
  Future<T?> fetch() async {
    if (!enabled) return null;

    /// if isLoading/isRefetching is true that means its already fetching/
    /// refetching. So [_execute] again can create a race condition
    if (isLoading || isRefetching || (hasData && !isPreviousData)) return data;
    status = QueryStatus.loading;
    notifyListeners();
    return execute().then((_) {
      fetched = true;
      return data;
    });
  }

  /// refetches a valid or invalid [Query]
  ///
  /// When called before calling [fetch] in a [Query] it'll
  /// automatically run [fetch]
  ///
  /// But if it's used to fetch the first data of a non-enabled [Query]
  /// aka `LazyQuery`, it'll execute the task & will set the status
  /// `enabled=true`
  ///
  /// If a [refetch] is already running in the background it'll just return
  /// the current available [data] instead of running the task to prevent
  /// race conditions
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
    return await execute().then((_) => data);
  }

  @protected
  FutureOr<void> setData();
  @protected
  void setError(dynamic);

  /// Sets the [externalData] from outside of the query
  ///
  /// Remember, it's for the very instance of [Query]
  /// So this won't persist through later UI/[Query] updates
  void setExternalData(Outside externalData) {
    _prevUsedExternalData = _externalData;
    _externalData = externalData;
  }

  /// Resets the query
  ///
  /// The values of internal state of the query are reset to the
  /// initial ones
  void reset() {
    refetchCount = 0;
    data = _previousData ?? _initialData;
    error = null;
    fetched = false;
    status = QueryStatus.idle;
    retryAttempts = 0;
    _onDataListeners.clear();
    _onErrorListeners.clear();
    mounts.clear();
  }

  /// Update configurations of the query
  /// after already creating the Query instance
  ///
  /// Remember, it's just for the single query instance
  /// In the next UI update/render the options will get reset
  /// to the default ones defined in the [QueryJob] or [QueryBowlScope]
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
      _refetchIntervalTimer = createRefetchTimer();
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

  /// checks if the application is connected to internet in any mean
  ///
  /// It's true when any one this is connected -
  /// - ethernet
  /// - mobile
  /// - wifi
  Future<bool> isInternetConnected() async {
    return isConnectedToInternet(await _connectivity.checkConnectivity());
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

  /// invalidates the query
  ///
  /// Forcefully makes the query stale & expired which results in a refetch
  /// when met conditions
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
  bool get isPreviousData {
    return _previousData != null ? _previousData == data : false;
  }

  String get debugLabel;

  @override
  String toString() {
    return debugLabel;
  }

  operator ==(other);
}
