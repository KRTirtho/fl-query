import 'dart:async';

import 'package:flutter/widgets.dart';

enum QueryStatus {
  failed,
  succeed,
  pending,
  refetching;
}

typedef QueryTaskFunction<T> = FutureOr<T> Function(String);

typedef QueryListener<T> = FutureOr<void> Function(T);

typedef ListenerUnsubscriber = void Function();

class Query<T> extends ChangeNotifier {
  // all params
  final String queryKey;
  QueryTaskFunction<T> task;
  final int retries;
  final Duration retryDelay;
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

  Query({
    required this.queryKey,
    required this.task,
    required Duration staleTime,
    this.retries = 3,
    this.retryDelay = const Duration(milliseconds: 200),
    T? initialData,
    QueryListener<T>? onData,
    QueryListener<dynamic>? onError,
  })  : status = QueryStatus.pending,
        _staleTime = staleTime,
        data = initialData,
        _onData = onData,
        _onError = onError,
        updatedAt = DateTime.now();

  // all getters & setters
  bool get hasData => data != null && error == null;
  bool get hasError =>
      status == QueryStatus.failed && error != null && data == null;
  bool get isLoading =>
      status == QueryStatus.pending && data == null && error == null;
  bool get isRefetching =>
      status == QueryStatus.refetching && data == null && error == null;
  bool get isSucceeded => status == QueryStatus.succeed && data != null;

  // all methods

  /// Calls the task function & doesn't check if there's already
  /// cached data available
  Future<void> _execute({bool isFetch = true}) async {
    try {
      retryAttempts = 0;
      status = isFetch ? QueryStatus.pending : QueryStatus.refetching;
      data = await task(queryKey);
      updatedAt = DateTime.now();
      status = QueryStatus.succeed;
      _onData?.call(data!);
      notifyListeners();
    } catch (e) {
      status = QueryStatus.failed;
      error = e;
      _onError?.call(e);
      notifyListeners();
      // retrying for retry count if failed for the first time
      while (retryAttempts <= retries) {
        await Future.delayed(retryDelay);
        try {
          data = await task(queryKey);
          status = QueryStatus.succeed;
          _onData?.call(data!);
          notifyListeners();
          break;
        } catch (e) {
          status = QueryStatus.failed;
          error = e;
          retryAttempts++;
          _onError?.call(e);
          notifyListeners();
        }
      }
    }
  }

  Future<T?> fetch() async {
    if (!_isStaleData() && hasData) {
      return data;
    }
    return _execute().then((_) {
      fetched = true;
      return data;
    });
  }

  Future<T?> refetch() {
    refetchCount++;
    return _execute(isFetch: false).then((_) => data);
  }

  bool _isStaleData() {
    // when current DateTime is after [update_at + stale_time] it means
    // the data has become stale
    return DateTime.now().isAfter(updatedAt.add(_staleTime));
  }
}
