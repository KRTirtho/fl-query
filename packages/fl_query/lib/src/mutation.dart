import 'dart:async';

import 'package:fl_query/fl_query.dart';
import 'package:fl_query/src/base_operation.dart';
import 'package:fl_query/src/mixins/autocast.dart';
import 'package:fl_query/src/models/mutation_job.dart';
import 'package:flutter/widgets.dart';

enum MutationStatus {
  error,
  success,
  loading,
  idle,
}

typedef MutationListenerReturnable<T, R> = FutureOr<R> Function(T);

typedef MutationListener<T, V> = FutureOr<void> Function(
  T payload,
  V variables,
  dynamic context,
);

typedef MutationTaskFunction<T, V> = FutureOr<T> Function(
    String queryKey, V variables);

class Mutation<T extends Object, V> extends BaseOperation<T, dynamic>
    with AutoCast {
  // all params
  final String mutationKey;
  MutationTaskFunction<T, V> task;

  MutationStatus status;

  dynamic _sideEffectContext;

  @protected
  final Set<MutationListener<T, V>> _onDataListeners = {};
  @protected
  final Set<MutationListener<dynamic, V>> _onErrorListeners = {};
  @protected
  final Set<MutationListenerReturnable<V, dynamic>> _onMutateListeners = {};

  // using late as _variables will only be used after a [mutate] or
  // [mutateAsync] is executed
  late V _variables;

  Mutation({
    required this.mutationKey,
    required this.task,
    required super.retries,
    required super.retryDelay,
    required Duration cacheTime,
    MutationListener<T, V>? onData,
    MutationListener<dynamic, V>? onError,
    MutationListenerReturnable<V, dynamic>? onMutate,
  })  : status = MutationStatus.idle,
        super(cacheTime: cacheTime) {
    if (onData != null) _onDataListeners.add(onData);
    if (onError != null) _onErrorListeners.add(onError);
    if (onMutate != null) _onMutateListeners.add(onMutate);
  }

  Mutation.fromOptions(
    MutationJob<T, V> options, {
    MutationListener<T, V>? onData,
    MutationListener<dynamic, V>? onError,
    MutationListenerReturnable<V, dynamic>? onMutate,
  })  : mutationKey = options.mutationKey,
        task = options.task,
        status = MutationStatus.idle,
        super(
          retries: options.retries ?? 3,
          retryDelay: options.retryDelay ?? const Duration(milliseconds: 200),
          cacheTime: options.cacheTime ?? const Duration(minutes: 5),
        ) {
    if (onData != null) _onDataListeners.add(onData);
    if (onError != null) _onErrorListeners.add(onError);
  }

  // all methods

  /// Calls the task function & doesn't check if there's already
  /// cached data available
  Future<void> _execute(V variables) async {
    try {
      status = MutationStatus.loading;
      notifyListeners();
      retryAttempts = 0;
      for (final onMutate in _onMutateListeners) {
        _sideEffectContext = await onMutate(variables);
      }
      data = await task(mutationKey, variables);
      updatedAt = DateTime.now();
      status = MutationStatus.success;
      for (final onData in _onDataListeners) {
        onData(data!, _variables, _sideEffectContext);
      }
      notifyListeners();
    } catch (e) {
      if (retries == 0) {
        status = MutationStatus.error;
        error = e;
        for (final onError in _onErrorListeners) {
          onError(error, variables, _sideEffectContext);
        }
        notifyListeners();
      } else {
        // retrying for retry count if failed for the first time
        while (retryAttempts <= retries) {
          await Future.delayed(retryDelay);
          try {
            for (final onMutate in _onMutateListeners) {
              _sideEffectContext = onMutate(variables);
            }
            data = await task(mutationKey, variables);
            status = MutationStatus.success;
            for (final onData in _onDataListeners) {
              onData(data!, variables, _sideEffectContext);
            }
            notifyListeners();
            break;
          } catch (e) {
            if (retryAttempts == retries) {
              status = MutationStatus.error;
              error = e;
              for (final onError in _onErrorListeners) {
                onError(error, variables, _sideEffectContext);
              }
              notifyListeners();
            }
            retryAttempts++;
          }
        }
      }
    }
  }

  void addDataListener(MutationListener<T, V> listener) {
    _onDataListeners.add(listener);
  }

  void addErrorListener(MutationListener<dynamic, V> listener) {
    _onErrorListeners.add(listener);
  }

  void addMutateListener(MutationListenerReturnable<V, dynamic> listener) {
    _onMutateListeners.add(listener);
  }

  void removeDataListener(MutationListener<T, V> listener) {
    _onDataListeners.remove(listener);
  }

  void removeErrorListener(MutationListener<dynamic, V> listener) {
    _onErrorListeners.remove(listener);
  }

  void removeMutateListener(MutationListenerReturnable<V, dynamic> listener) {
    _onMutateListeners.remove(listener);
  }

  void mutate(
    V variables, {
    MutationListener<T, V>? onData,
    MutationListener<dynamic, V>? onError,
  }) {
    _variables = variables;
    if (onData != null) _onDataListeners.add(onData);
    if (onError != null) _onErrorListeners.add(onError);
    _execute(variables).then((_) {
      _onDataListeners.remove(onData);
      _onErrorListeners.remove(onError);
    });
  }

  Future<T?> mutateAsync(V variables) async {
    _variables = variables;
    return await _execute(variables).then((_) => data);
  }

  /// Update configurations of the mutation after already creating the
  /// Mutation instance
  void updateDefaultOptions({
    Duration? cacheTime,
  }) {
    if (this.cacheTime == Duration(minutes: 5) && cacheTime != null)
      this.cacheTime = cacheTime;

    notifyListeners();
  }

  void reset() {
    data = null;
    retryAttempts = 0;
    updatedAt = DateTime.now();
    _onDataListeners.clear();
    _onErrorListeners.clear();
    status = MutationStatus.idle;
    _onMutateListeners.clear();
    _sideEffectContext = null;
  }

  bool get isError => status == MutationStatus.error;
  bool get isIdle => status == MutationStatus.idle;
  bool get isLoading => status == MutationStatus.loading;
  bool get isSuccess => status == MutationStatus.success;

  @override
  bool operator ==(other) {
    return (other is Mutation<T, V> && other.mutationKey == mutationKey) ||
        identical(other, this);
  }
}
