import 'dart:async';

import 'package:fl_query/models/query_job.dart';
import 'package:flutter/widgets.dart';

enum QueryStatus {
  failed,
  succeed,
  pending,
  refetching;
}

typedef QueryTaskFunction<T, Outside> = FutureOr<T> Function(String, Outside);

typedef QueryListener<T> = FutureOr<void> Function(T);

typedef ListenerUnsubscriber = void Function();

typedef QueryUpdateFunction<T> = FutureOr<T> Function(T? oldData);

class Query<T extends Object, Outside> extends ChangeNotifier {
  // all params
  final String queryKey;
  QueryTaskFunction<T, Outside> task;

  /// The number of times the query should refetch in the time of error
  /// before giving up
  final int retries;
  final Duration retryDelay;
  final T? _initialData;

  // got from global options
  final Duration _staleTime;
  final Duration _cacheTime;

  // all properties
  T? data;
  dynamic error;
  QueryStatus status;

  /// total count of how many times the query retried to get a successful
  /// result
  int retryAttempts = 0;
  DateTime updatedAt;
  int refetchCount = 0;
  bool enabled;

  @protected
  bool fetched = false;

  @protected
  final Set<QueryListener<T>> onDataListeners = Set<QueryListener<T>>();
  @protected
  final Set<QueryListener<dynamic>> onErrorListeners =
      Set<QueryListener<dynamic>>();

  // externalData will always be passed to the task Callback
  // it will change based on the presence of QueryBuilder
  Outside _externalData;

  Outside? _prevUsedExternalData;

  /// used for keeping track of query activity. If the are no mounts &
  /// the passed cached time is over than the query is removed from
  /// storage/cache
  Set<ValueKey<String>> _mounts = {};

  Query({
    required this.queryKey,
    required this.task,
    required Duration staleTime,
    required Duration cacheTime,
    required Outside externalData,
    required this.retries,
    required this.retryDelay,
    T? initialData,
    this.enabled = true,
    QueryListener<T>? onData,
    QueryListener<dynamic>? onError,
  })  : status = QueryStatus.pending,
        _staleTime = staleTime,
        _cacheTime = cacheTime,
        _initialData = initialData,
        _externalData = externalData,
        data = initialData,
        updatedAt = DateTime.now() {
    if (onData != null) onDataListeners.add(onData);
    if (onError != null) onErrorListeners.add(onError);
  }

  Query.fromOptions(
    QueryJob<T, Outside> options, {
    required Outside externalData,
    QueryListener<T>? onData,
    QueryListener<dynamic>? onError,
  })  : queryKey = options.queryKey,
        enabled = options.enabled ?? true,
        task = options.task,
        retries = options.retries ?? 3,
        retryDelay = options.retryDelay ?? const Duration(milliseconds: 200),
        _staleTime = options.staleTime ?? const Duration(milliseconds: 500),
        _cacheTime = options.cacheTime ?? const Duration(minutes: 5),
        _initialData = options.initialData,
        _externalData = externalData,
        data = options.initialData,
        status = QueryStatus.pending,
        updatedAt = DateTime.now() {
    if (onData != null) onDataListeners.add(onData);
    if (onError != null) onErrorListeners.add(onError);
  }

  // all getters & setters
  bool get hasData => data != null && error == null;
  bool get hasError =>
      status == QueryStatus.failed && error != null && data == null;
  bool get isLoading =>
      status == QueryStatus.pending && data == null && error == null;
  bool get isRefetching =>
      status == QueryStatus.refetching && (data != null || error != null);
  bool get isSucceeded => status == QueryStatus.succeed && data != null;
  bool get isIdle => isSucceeded && error == null;
  bool get isInactive => _mounts.isEmpty;
  Outside get externalData => _externalData;
  Outside? get prevUsedExternalData => _prevUsedExternalData;

  // all methods

  void mount(ValueKey<String> uKey) {
    _mounts.add(uKey);
  }

  void unmount(ValueKey<String> uKey) {
    if (_mounts.length == 1) {
      Future.delayed(_cacheTime, () {
        _mounts.remove(uKey);
        // for letting know QueryBowl that this one's time has come for
        // getting crushed
        notifyListeners();
      });
    } else {
      _mounts.remove(uKey);
    }
  }

  /// Calls the task function & doesn't check if there's already
  /// cached data available
  Future<void> _execute() async {
    try {
      retryAttempts = 0;
      data = await task(queryKey, _externalData);
      _prevUsedExternalData = _externalData;
      updatedAt = DateTime.now();
      status = QueryStatus.succeed;
      for (final onData in onDataListeners) {
        onData(data!);
      }
      notifyListeners();
    } catch (e) {
      if (retries == 0) {
        status = QueryStatus.failed;
        error = e;
        for (final onError in onErrorListeners) {
          onError(error);
        }
        notifyListeners();
      } else {
        // retrying for retry count if failed for the first time
        while (retryAttempts <= retries) {
          await Future.delayed(retryDelay);
          try {
            data = await task(queryKey, _externalData);
            _prevUsedExternalData = _externalData;
            status = QueryStatus.succeed;
            for (final onData in onDataListeners) {
              onData(data!);
            }
            notifyListeners();
            break;
          } catch (e) {
            if (retryAttempts == retries) {
              status = QueryStatus.failed;
              error = e;
              for (final onError in onErrorListeners) {
                onError(error);
              }
              notifyListeners();
            }
            retryAttempts++;
          }
        }
      }
    }
  }

  Future<T?> fetch() async {
    status = QueryStatus.pending;
    notifyListeners();
    if (!enabled) return null;
    if (!isStale && hasData) {
      return data;
    }
    return _execute().then((_) {
      fetched = true;
      return data;
    });
  }

  Future<T?> refetch() async {
    // cannot let run multiple refetch at the same time. It can cause
    // race-condition
    if (isRefetching) return null;
    status = QueryStatus.refetching;
    refetchCount++;
    // disabling the lazy query bound when query was actually called
    if (!enabled) enabled = false;
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
    if (data == newData) {
      // TODO: Better Error handling & Error structure
      throw Exception(
          "[fl_query] new instance of data should be returned because of immutability");
    }
    data = newData;
    status = QueryStatus.succeed;
    notifyListeners();
  }

  setExternalData(Outside externalData) {
    _externalData = externalData;
  }

  void reset() {
    refetchCount = 0;
    data = _initialData;
    error = null;
    fetched = false;
    status = QueryStatus.pending;
    retryAttempts = 0;
    onDataListeners.clear();
    onErrorListeners.clear();
    _mounts.clear();
  }

  bool get isStale {
    // when current DateTime is after [update_at + stale_time] it means
    // the data has become stale
    return DateTime.now().isAfter(updatedAt.add(_staleTime));
  }

  A? cast<A>() => this is A ? this as A : null;

  String get debugLabel => "Query($queryKey)";

  @override
  String toString() {
    return debugLabel;
  }
}
