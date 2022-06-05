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

class Query<T extends Object, Outside> extends ChangeNotifier {
  // all params
  final String queryKey;
  QueryTaskFunction<T, Outside> task;
  final int retries;
  final Duration retryDelay;
  final T? _initialData;

  // got from global options
  final Duration _staleTime;

  // all properties
  T? data;
  dynamic error;
  QueryStatus status;
  int retryAttempts = 0;
  DateTime updatedAt;
  int refetchCount = 0;

  @protected
  bool fetched = false;

  final QueryListener<T>? _onData;
  final QueryListener<dynamic>? _onError;

  // externalData will always be passed to the task Callback
  // it will change based on the presence of QueryBuilder
  Outside _externalData;

  Outside? _prevUsedExternalData;

  Query({
    required this.queryKey,
    required this.task,
    required Duration staleTime,
    required Outside externalData,
    required this.retries,
    required this.retryDelay,
    T? initialData,
    QueryListener<T>? onData,
    QueryListener<dynamic>? onError,
  })  : status = QueryStatus.pending,
        _staleTime = staleTime,
        _initialData = initialData,
        _externalData = externalData,
        data = initialData,
        _onData = onData,
        _onError = onError,
        updatedAt = DateTime.now();

  Query.fromOptions(QueryJob<T, Outside> options,
      {required Outside externalData})
      : queryKey = options.queryKey,
        task = options.task,
        retries = options.retries ?? 3,
        retryDelay = options.retryDelay ?? const Duration(milliseconds: 200),
        _staleTime = options.staleTime ?? const Duration(days: 1),
        _initialData = options.initialData,
        _externalData = externalData,
        _onData = options.onData,
        _onError = options.onError,
        data = options.initialData,
        status = QueryStatus.pending,
        updatedAt = DateTime.now();

  // all getters & setters
  bool get hasData => data != null && error == null;
  bool get hasError =>
      status == QueryStatus.failed && error != null && data == null;
  bool get isLoading =>
      status == QueryStatus.pending && data == null && error == null;
  bool get isRefetching =>
      status == QueryStatus.refetching && (data != null || error != null);
  bool get isSucceeded => status == QueryStatus.succeed && data != null;
  Outside get externalData => _externalData;
  Outside? get prevUsedExternalData => _prevUsedExternalData;

  // all methods

  /// Calls the task function & doesn't check if there's already
  /// cached data available
  Future<void> _execute() async {
    try {
      retryAttempts = 0;
      data = await task(queryKey, _externalData);
      _prevUsedExternalData = _externalData;
      updatedAt = DateTime.now();
      status = QueryStatus.succeed;
      _onData?.call(data!);
      notifyListeners();
    } catch (e) {
      if (retries == 0) {
        status = QueryStatus.failed;
        error = e;
        _onError?.call(e);
        notifyListeners();
      } else {
        // retrying for retry count if failed for the first time
        while (retryAttempts <= retries) {
          await Future.delayed(retryDelay);
          try {
            data = await task(queryKey, _externalData);
            _prevUsedExternalData = _externalData;
            status = QueryStatus.succeed;
            _onData?.call(data!);
            notifyListeners();
            break;
          } catch (e) {
            if (retryAttempts == retries) {
              status = QueryStatus.failed;
              error = e;
              _onError?.call(e);
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
    if (!isStale && hasData) {
      return data;
    }
    return _execute().then((_) {
      fetched = true;
      return data;
    });
  }

  Future<T?> refetch() {
    status = QueryStatus.refetching;
    refetchCount++;
    notifyListeners();
    return _execute().then((_) => data);
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
  update(FutureOr<T> Function(T? data) updateFn) async {
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
  }

  bool get isStale {
    // when current DateTime is after [update_at + stale_time] it means
    // the data has become stale
    return DateTime.now().isAfter(updatedAt.add(_staleTime));
  }

  A? cast<A>() => this is A ? this as A : null;
}
