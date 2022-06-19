import 'dart:async';

import 'package:fl_query/models/mutation_job.dart';
import 'package:flutter/widgets.dart';

enum MutationStatus {
  failed,
  succeed,
  pending,
}

typedef MutationListener<T> = FutureOr<void> Function(T);

typedef MutationTaskFunction<T, V> = FutureOr<T> Function(String, V);

class Mutation<T extends Object, V> extends ChangeNotifier {
  // all params
  final String mutationKey;
  MutationTaskFunction<T, V> task;
  final int retries;
  final Duration retryDelay;
  final Duration _cacheTime;

  // all properties
  T? data;
  dynamic error;
  MutationStatus status;

  /// total count of how many times the query retried to get a successful
  /// result
  int retryAttempts = 0;
  DateTime updatedAt;

  /// used for keeping track of mutation activity. If the are no mounts &
  /// the passed cached time is over than the mutation is removed from
  /// storage/cache
  Set<Widget> _mounts = {};

  @protected
  final Set<MutationListener<T>> onDataListeners = {};
  @protected
  final Set<MutationListener<dynamic>> onErrorListeners = {};
  @protected
  final Set<MutationListener<V>> onMutateListeners = {};

  Mutation({
    required this.mutationKey,
    required this.task,
    required this.retries,
    required this.retryDelay,
    required Duration cacheTime,
    MutationListener<T>? onData,
    MutationListener<dynamic>? onError,
    MutationListener<V>? onMutate,
  })  : status = MutationStatus.pending,
        updatedAt = DateTime.now(),
        _cacheTime = cacheTime {
    if (onData != null) onDataListeners.add(onData);
    if (onError != null) onErrorListeners.add(onError);
    if (onMutate != null) onMutateListeners.add(onMutate);
  }

  Mutation.fromOptions(
    MutationJob<T, V> options, {
    MutationListener<T>? onData,
    MutationListener<dynamic>? onError,
    MutationListener<V>? onMutate,
  })  : mutationKey = options.mutationKey,
        task = options.task,
        retries = options.retries ?? 3,
        retryDelay = options.retryDelay ?? const Duration(milliseconds: 200),
        _cacheTime = options.cacheTime ?? const Duration(minutes: 5),
        status = MutationStatus.pending,
        updatedAt = DateTime.now() {
    if (onData != null) onDataListeners.add(onData);
    if (onError != null) onErrorListeners.add(onError);
  }

  // all getters & setters
  bool get hasData => data != null && error == null;
  bool get hasError =>
      status == MutationStatus.failed && error != null && data == null;
  bool get isLoading =>
      status == MutationStatus.pending && data == null && error == null;
  bool get isSucceeded => status == MutationStatus.succeed && data != null;
  bool get isIdle => isSucceeded && error == null;
  bool get isInactive => _mounts.isEmpty;
  // all methods

  void mount(Widget widget) {
    _mounts.add(widget);
  }

  void unmount(Widget widget) {
    if (_mounts.length == 1) {
      Future.delayed(_cacheTime, () {
        _mounts.remove(widget);
        // for letting know QueryBowl that this one's time has come for
        // getting crushed
        notifyListeners();
      });
    } else {
      _mounts.remove(widget);
    }
  }

  /// Calls the task function & doesn't check if there's already
  /// cached data available
  Future<void> _execMutation(V variables) async {
    try {
      retryAttempts = 0;
      for (final onMutate in onMutateListeners) {
        onMutate(variables);
      }
      data = await task(mutationKey, variables);
      updatedAt = DateTime.now();
      status = MutationStatus.succeed;
      for (final onData in onDataListeners) {
        onData(data!);
      }
      notifyListeners();
    } catch (e) {
      if (retries == 0) {
        status = MutationStatus.failed;
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
            status = MutationStatus.succeed;
            for (final onData in onDataListeners) {
              onData(data!);
            }
            notifyListeners();
            break;
          } catch (e) {
            if (retryAttempts == retries) {
              status = MutationStatus.failed;
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
    _execMutation(variables).then((_) {
      onDataListeners.remove(onData);
      onErrorListeners.remove(onError);
    });
  }

  Future<T?> mutateAsync(V variables) async {
    return await _execMutation(variables).then((_) => data);
  }

  reset() {
    data = null;
    retryAttempts = 0;
    updatedAt = DateTime.now();
    onDataListeners.clear();
    onErrorListeners.clear();
    status = MutationStatus.pending;
    onMutateListeners.clear();
  }

  A? cast<A>() => this is A ? this as A : null;
}
