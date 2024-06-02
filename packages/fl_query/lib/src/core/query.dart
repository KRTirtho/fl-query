import 'dart:async';

import 'package:fl_query/src/collections/json_config.dart';
import 'package:fl_query/src/collections/refresh_config.dart';
import 'package:fl_query/src/collections/retry_config.dart';
import 'package:fl_query/src/core/client.dart';
import 'package:fl_query/src/core/mixins/retryer.dart';
import 'package:fl_query/src/core/mixins/validation.dart';
import 'package:fl_query/src/widgets/state_resolvers/query_state.dart';
import 'package:flutter/widgets.dart' hide Listener;
import 'package:hive_flutter/adapters.dart';
import 'package:mutex/mutex.dart';
import 'package:state_notifier/state_notifier.dart';
import 'package:async/async.dart';

typedef QueryFn<DataType> = FutureOr<DataType?> Function();

class QueryState<DataType, ErrorType> with Invalidation {
  final DataType? data;
  final ErrorType? error;
  final DateTime updatedAt;
  final Duration staleDuration;

  final bool _loading;

  const QueryState({
    this.data,
    this.error,
    required this.updatedAt,
    required this.staleDuration,
    bool loading = false,
  }) : _loading = loading;

  // Use functions to allow setting nulls
  // https://stackoverflow.com/a/71591609
  QueryState<DataType, ErrorType> copyWith({
    DataType? Function()? data,
    ErrorType? Function()? error,
    DateTime? updatedAt,
    bool? loading,
  }) {
    return QueryState<DataType, ErrorType>(
      updatedAt: updatedAt ?? this.updatedAt,
      staleDuration: staleDuration,
      data: data != null ? data() : this.data,
      error: error != null ? error() : this.error,
      loading: loading ?? this._loading,
    );
  }
}

class Query<DataType, ErrorType>
    extends StateNotifier<QueryState<DataType, ErrorType>>
    with Retryer<DataType, ErrorType> {
  final String key;

  final RefreshConfig refreshConfig;
  final RetryConfig retryConfig;
  final JsonConfig<DataType>? jsonConfig;

  QueryFn<DataType> _queryFn;

  Query(
    this.key,
    QueryFn<DataType> queryFn, {
    DataType? initial,
    required this.retryConfig,
    required this.refreshConfig,
    this.jsonConfig,
  })  : _box = Hive.lazyBox(QueryClient.queryCachePrefix),
        _dataController = StreamController<DataType>.broadcast(),
        _errorController = StreamController<ErrorType>.broadcast(),
        _initial = initial,
        _queryFn = queryFn,
        super(QueryState<DataType, ErrorType>(
          updatedAt: DateTime.now(),
          staleDuration: refreshConfig.staleDuration,
          data: initial,
        )) {
    if (jsonConfig != null) {
      _mutex.protect(() async {
        final json = await _box.get(key);
        if (json != null) {
          _initial = jsonConfig!.fromJson(
            Map.castFrom<dynamic, dynamic, String, dynamic>(json),
          );
          state = state.copyWith(data: () => _initial, updatedAt: DateTime.now());
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

    // Listen to network changes and cancel any ongoing operations

    bool wasConnected = true;
    _connectivitySubscription = QueryClient.connectivity.onConnectivityChanged
        .listen((isConnected) async {
      try {
        if (isConnected &&
            !wasConnected &&
            state.isStale &&
            refreshConfig.refreshOnNetworkStateChange) {
          await refresh();
        } else if (!isConnected &&
            _mutex.isLocked &&
            retryConfig.cancelWhenOffline) {
          await _operation?.cancel();
        }
      } finally {
        wasConnected = isConnected;
      }
    });
  }

  DataType? _initial;
  final LazyBox _box;
  final _mutex = Mutex();
  final StreamController<DataType> _dataController;
  final StreamController<ErrorType> _errorController;
  StreamSubscription<bool>? _connectivitySubscription;

  bool get isInitial => hasData && state.data == _initial;
  bool get isLoading =>
      (isInitial && !hasError && state._loading) ||
      (!hasData && !hasError && state._loading);
  bool get isRefreshing =>
      ((!isInitial && hasData) || hasError) && state._loading;
  bool get isFetching => isLoading || isRefreshing;
  bool get isInactive => !hasListeners;
  bool get hasData => state.data != null;
  bool get hasError => state.error != null;

  DataType? get data => state.data;
  ErrorType? get error => state.error;
  Stream<DataType> get dataStream => _dataController.stream;
  Stream<ErrorType> get errorStream => _errorController.stream;

  CancelableOperation<void>? _operation;

  Future<void> _operate() async {
    if (!QueryClient.connectivity.isConnectedSync &&
        retryConfig.cancelWhenOffline) {
      return;
    }
    return _mutex.protect(() async {
      state = state.copyWith(loading: true);
      _operation = cancellableRetryOperation(
        _queryFn,
        config: retryConfig,
        onSuccessful: (DataType? data) {
          state = state.copyWith(
            data: () => data,
            error: () => null,
            updatedAt: DateTime.now(),
            loading: false,
          );
          if (data is DataType) {
            _dataController.add(data);
            if (jsonConfig != null) {
              _box.put(
                key,
                jsonConfig!.toJson(data),
              );
            }
          }
        },
        onFailed: (ErrorType? error) {
          state = state.copyWith(
            error: () => error,
            updatedAt: DateTime.now(),
            loading: false,
          );
          if (error is ErrorType) _errorController.add(error);
        },
      );

      return await _operation?.valueOrCancellation(null);
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
    if (_queryFn == queryFn) return;
    _queryFn = queryFn;
    if ((state.isStale && !hasError) || refreshConfig.refreshOnQueryFnChange) {
      refresh();
    }
  }

  void setData(DataType data) {
    state = state.copyWith(
      data: () => data,
      updatedAt: DateTime.now(),
      loading: false,
    );
  }

  Future<void> reset() async {
    await _operation?.cancel();
    state = state.copyWith(
      data: () => _initial,
      updatedAt: DateTime.now(),
      loading: false,
    );
    _box.delete(key);
  }

  Widget resolve(
    Widget Function(DataType data) data, {
    required Widget Function(ErrorType data) error,
    required Widget Function() loading,
    Widget Function()? offline,
  }) {
    if (hasData) {
      return data(this.data!);
    } else if (!QueryClient.connectivity.isConnectedSync) {
      return offline != null ? offline() : loading();
    } else if (hasError) {
      return error(this.error!);
    } else {
      return loading();
    }
  }

  Widget resolveWith(
    BuildContext context,
    Widget Function(DataType data) data, {
    required Widget Function(ErrorType error)? error,
    required Widget Function()? loading,
    Widget Function()? offline,
  }) {
    final resolvents = QueryStateResolverProvider.of(context);

    assert(
      resolvents.error != null || error != null,
      'You must provide an error widget or an error resolver using `QueryStateResolverProvider`',
    );

    assert(
      resolvents.loading != null || loading != null,
      'You must provide a loading widget or a loading resolver using `QueryStateResolverProvider`',
    );

    return resolve(
      data,
      error: resolvents.error != null
          ? (e) => resolvents.error!(e as dynamic)
          : error!,
      loading: (resolvents.loading ?? loading)!,
      offline: resolvents.offline ?? offline,
    );
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
  void dispose() {
    _operation?.cancel();
    _connectivitySubscription?.cancel();
    _dataController.close();
    _errorController.close();
    super.dispose();
  }

  @override
  operator ==(Object other) {
    return identical(this, other) || (other is Query && key == other.key);
  }

  @override
  int get hashCode => key.hashCode;

  Query<NewDataType, NewErrorType> cast<NewDataType, NewErrorType>() {
    return this as Query<NewDataType, NewErrorType>;
  }
}
