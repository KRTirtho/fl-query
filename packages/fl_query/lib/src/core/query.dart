import 'dart:async';

import 'package:fl_query/src/collections/default_configs.dart';
import 'package:fl_query/src/collections/json_config.dart';
import 'package:fl_query/src/collections/refresh_config.dart';
import 'package:fl_query/src/collections/retry_config.dart';
import 'package:fl_query/src/core/retryer.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:mutex/mutex.dart';
import 'package:state_notifier/state_notifier.dart';

typedef QueryFn<T> = FutureOr<T?> Function();

class QueryState<T, E> {
  final T? data;
  final E? error;
  final QueryFn<T> queryFn;

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

  QueryState<T, E> copyWith({
    T? data,
    E? error,
    QueryFn<T>? queryFn,
  }) {
    return QueryState<T, E>(
      updatedAt: DateTime.now(),
      staleDuration: staleDuration,
      data: data ?? this.data,
      error: error ?? this.error,
      queryFn: queryFn ?? this.queryFn,
    );
  }
}

class Query<T, E, K> extends StateNotifier<QueryState<T, E>>
    with Retryer<T, E> {
  final ValueKey<K> key;
  final T? initial;

  final RefreshConfig refreshConfig;
  final RetryConfig retryConfig;
  final JsonConfig<T>? jsonConfig;
  Query(
    this.key,
    QueryFn<T> queryFn, {
    this.initial,
    this.retryConfig = DefaultConstants.retryConfig,
    this.refreshConfig = DefaultConstants.refreshConfig,
    this.jsonConfig,
  })  : _box = Hive.lazyBox("cache"),
        super(QueryState<T, E>(
          updatedAt: DateTime.now(),
          staleDuration: refreshConfig.staleDuration,
          data: initial,
          queryFn: queryFn,
        )) {
    if (jsonConfig != null) {
      _mutex.protect(() async {
        final json = await _box.get(key);
        if (json != null) {
          state = state.copyWith(data: jsonConfig!.fromJson(json));
        }
      });

      Timer.periodic(refreshConfig.refreshInterval, (_) async {
        if (state.isStale) {
          await refresh();
        }
      });
    }
  }

  final LazyBox _box;
  final _mutex = Mutex();

  bool get isInitial => state.data == initial;
  bool get isLoading => isInitial ? _mutex.isLocked : !hasData && !hasError;
  bool get isRefreshing =>
      ((!isInitial && hasData) || hasError) && _mutex.isLocked;
  bool get hasData => state.data != null;
  bool get hasError => state.error != null;

  T? get data => state.data;
  E? get error => state.error;

  Future<void> _operate() {
    return _mutex.protect(() async {
      retryOperation(
        state.queryFn,
        config: retryConfig,
        onSuccessful: (T? data) {
          state = state.copyWith(data: data);
          if (jsonConfig != null) {
            _box.put(
              key,
              jsonConfig!.toJson(data!),
            );
          }
        },
        onFailed: (E? error) {
          state = state.copyWith(error: error);
        },
      );
    });
  }

  Future<T?> fetch() async {
    if (_mutex.isLocked || hasData || hasError) return state.data;
    return _operate().then((_) => state.data);
  }

  Future<T?> refresh() async {
    if (_mutex.isLocked) return state.data;
    return _operate().then((_) => state.data);
  }

  void updateQueryFn(QueryFn<T> queryFn) {
    state = state.copyWith(queryFn: queryFn);
  }

  void setData(T data) {
    state = state.copyWith(data: data);
  }
}
