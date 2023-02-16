import 'dart:async';

import 'package:fl_query/src/collections/default_configs.dart';
import 'package:fl_query/src/collections/json_config.dart';
import 'package:fl_query/src/collections/refresh_config.dart';
import 'package:fl_query/src/collections/retry_config.dart';
import 'package:fl_query/src/core/retryer.dart';
import 'package:flutter/material.dart' hide Listener;
import 'package:hive_flutter/adapters.dart';
import 'package:mutex/mutex.dart';
import 'package:state_notifier/state_notifier.dart';

typedef QueryFn<DataType> = FutureOr<DataType?> Function();

class QueryState<DataType, ErrorType> {
  final DataType? data;
  final ErrorType? error;
  final QueryFn<DataType> queryFn;

  final DateTime updatedAt;
  final Duration staleDuration;

  const QueryState({
    this.data,
    this.error,
    required this.queryFn,
    required this.updatedAt,
    required this.staleDuration,
  });

  bool get isStale {
    return DateTime.now().difference(updatedAt) > staleDuration;
  }

  QueryState<DataType, ErrorType> copyWith({
    DataType? data,
    ErrorType? error,
    QueryFn<DataType>? queryFn,
  }) {
    return QueryState<DataType, ErrorType>(
      updatedAt: DateTime.now(),
      staleDuration: staleDuration,
      data: data ?? this.data,
      error: error ?? this.error,
      queryFn: queryFn ?? this.queryFn,
    );
  }
}

class Query<DataType, ErrorType, KeyType>
    extends StateNotifier<QueryState<DataType, ErrorType>>
    with Retryer<DataType, ErrorType> {
  final ValueKey<KeyType> key;

  final RefreshConfig refreshConfig;
  final RetryConfig retryConfig;
  final JsonConfig<DataType>? jsonConfig;

  Query(
    this.key,
    QueryFn<DataType> queryFn, {
    DataType? initial,
    this.retryConfig = DefaultConstants.retryConfig,
    this.refreshConfig = DefaultConstants.refreshConfig,
    this.jsonConfig,
  })  : _box = Hive.lazyBox("cache"),
        _dataController = StreamController<DataType>.broadcast(),
        _errorController = StreamController<ErrorType>.broadcast(),
        _initial = initial,
        super(QueryState<DataType, ErrorType>(
          updatedAt: DateTime.now(),
          staleDuration: refreshConfig.staleDuration,
          data: initial,
          queryFn: queryFn,
        )) {
    if (jsonConfig != null) {
      _mutex.protect(() async {
        final json = await _box.get(key.toString());
        if (json != null) {
          _initial = jsonConfig!.fromJson(
            Map.castFrom<dynamic, dynamic, String, dynamic>(json),
          );
          state = state.copyWith(data: _initial);
        }
      }).then((_) {
        if (hasListeners) {
          return fetch();
        }
      });
    } else {
      _initial = initial;
    }

    if (refreshConfig.refreshInterval > Duration.zero)
      Timer.periodic(refreshConfig.refreshInterval, (_) async {
        if (state.isStale) {
          await refresh();
        }
      });
  }

  DataType? _initial;
  final LazyBox _box;
  final _mutex = Mutex();
  final StreamController<DataType> _dataController;
  final StreamController<ErrorType> _errorController;

  bool get isInitial => hasData && state.data == _initial;
  bool get isLoading => isInitial ? _mutex.isLocked : !hasData && !hasError;
  bool get isRefreshing =>
      ((!isInitial && hasData) || hasError) && _mutex.isLocked;
  bool get isInactive => !hasListeners;
  bool get hasData => state.data != null;
  bool get hasError => state.error != null;

  DataType? get data => state.data;
  ErrorType? get error => state.error;
  Stream<DataType> get dataStream => _dataController.stream;
  Stream<ErrorType> get errorStream => _errorController.stream;

  Future<void> _operate() {
    return _mutex.protect(() async {
      retryOperation(
        state.queryFn,
        config: retryConfig,
        onSuccessful: (DataType? data) {
          state = state.copyWith(data: data);
          if (data != null) _dataController.add(data);
          if (jsonConfig != null && data != null) {
            _box.put(
              key.toString(),
              jsonConfig!.toJson(data),
            );
          }
        },
        onFailed: (ErrorType? error) {
          state = state.copyWith(error: error);
          if (error != null) _errorController.add(error);
        },
      );
    });
  }

  Future<DataType?> fetch() async {
    if (_mutex.isLocked || (hasData && !isInitial) || hasError)
      return state.data;
    return _operate().then((_) => state.data);
  }

  Future<DataType?> refresh() async {
    if (_mutex.isLocked) return state.data;
    return _operate().then((_) => state.data);
  }

  void updateQueryFn(QueryFn<DataType> queryFn) {
    if (state.queryFn == queryFn) return;
    // updatedAt is updated with copyWith so storing it
    // here to check if the query is stale later
    final stale = state.isStale;
    state = state.copyWith(queryFn: queryFn);
    if (stale || refreshConfig.refreshOnQueryFnChange) {
      refresh();
    }
  }

  void setData(DataType data) {
    state = state.copyWith(data: data);
  }

  @override
  RemoveListener addListener(Listener<QueryState<DataType, ErrorType>> listener,
      {bool fireImmediately = true}) {
    if (state.isStale || refreshConfig.refreshOnMount) {
      refresh();
    }
    return super.addListener(listener, fireImmediately: fireImmediately);
  }

  @override
  operator ==(Object other) {
    return identical(this, other) ||
        (other is Query && key.value == other.key.value);
  }

  @override
  int get hashCode => key.hashCode;

  Query<NewDataType, NewErrorType, NewKeyType>
      cast<NewDataType, NewErrorType, NewKeyType>() {
    return this as Query<NewDataType, NewErrorType, NewKeyType>;
  }
}
