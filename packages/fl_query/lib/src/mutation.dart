import 'dart:async';

import 'package:fl_query/src/base_operation.dart';
import 'package:fl_query/src/models/mutation_job.dart';
import 'package:fl_query/src/models/query_job.dart';
import 'package:fl_query/src/query.dart';
import 'package:fl_query/src/utils.dart';
import 'package:flutter/widgets.dart';
import 'package:collection/collection.dart';

enum MutationStatus {
  error,
  success,
  loading,
  idle,
}

typedef MutationListener<T> = FutureOr<void> Function(T);

typedef MutationTaskFunction<T, V> = FutureOr<T> Function(
    String queryKey, V variables);

class Mutation<T extends Object, V> extends BaseOperation<T, MutationStatus> {
  // all params
  final String mutationKey;
  MutationTaskFunction<T, V> task;

  @protected
  final Set<MutationListener<T>> onDataListeners = {};
  @protected
  final Set<MutationListener<dynamic>> onErrorListeners = {};
  @protected
  final Set<MutationListener<V>> onMutateListeners = {};

  Mutation({
    required this.mutationKey,
    required this.task,
    required super.retries,
    required super.retryDelay,
    required super.queryBowl,
    required Duration cacheTime,
    MutationListener<T>? onData,
    MutationListener<dynamic>? onError,
    MutationListener<V>? onMutate,
  }) : super(cacheTime: cacheTime, status: MutationStatus.idle) {
    if (onData != null) onDataListeners.add(onData);
    if (onError != null) onErrorListeners.add(onError);
    if (onMutate != null) onMutateListeners.add(onMutate);
  }

  Mutation.fromOptions(
    MutationJob<T, V> options, {
    MutationListener<T>? onData,
    MutationListener<dynamic>? onError,
    MutationListener<V>? onMutate,
    required super.queryBowl,
  })  : mutationKey = options.mutationKey,
        task = options.task,
        super(
          retries: options.retries ?? 3,
          retryDelay: options.retryDelay ?? const Duration(milliseconds: 200),
          cacheTime: options.cacheTime ?? const Duration(minutes: 5),
          status: MutationStatus.idle,
        ) {
    if (onData != null) onDataListeners.add(onData);
    if (onError != null) onErrorListeners.add(onError);
  }

  // all methods

  /// Calls the task function & doesn't check if there's already
  /// cached data available
  Future<void> _execute(V variables) async {
    try {
      status = MutationStatus.loading;
      notifyListeners();
      retryAttempts = 0;
      for (final onMutate in onMutateListeners) {
        onMutate(variables);
      }
      data = await task(mutationKey, variables);
      updatedAt = DateTime.now();
      status = MutationStatus.success;
      for (final onData in onDataListeners) {
        onData(data!);
      }
      notifyListeners();
    } catch (e) {
      if (retries == 0) {
        status = MutationStatus.error;
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
            for (final onMutate in onMutateListeners) {
              onMutate(variables);
            }
            data = await task(mutationKey, variables);
            status = MutationStatus.success;
            for (final onData in onDataListeners) {
              onData(data!);
            }
            notifyListeners();
            break;
          } catch (e) {
            if (retryAttempts == retries) {
              status = MutationStatus.error;
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

  void mutate(
    V variables, {
    MutationListener<T>? onData,
    MutationListener<dynamic>? onError,
  }) {
    if (onData != null) onDataListeners.add(onData);
    if (onError != null) onErrorListeners.add(onError);
    _execute(variables).then((_) {
      onDataListeners.remove(onData);
      onErrorListeners.remove(onError);
    });
  }

  Future<T?> mutateAsync(V variables) async {
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
    onDataListeners.clear();
    onErrorListeners.clear();
    status = MutationStatus.idle;
    onMutateListeners.clear();
  }

  A? cast<A>() => this is A ? this as A : null;

  @override
  bool get isError => status == MutationStatus.error;
  @override
  bool get isIdle => status == MutationStatus.idle;
  @override
  bool get isLoading => status == MutationStatus.loading;
  @override
  bool get isSuccess => status == MutationStatus.success;
}
