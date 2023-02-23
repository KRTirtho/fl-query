import 'dart:async';

import 'package:fl_query/src/collections/default_configs.dart';
import 'package:fl_query/src/collections/retry_config.dart';
import 'package:fl_query/src/core/retryer.dart';
import 'package:mutex/mutex.dart';
import 'package:state_notifier/state_notifier.dart';

typedef MutationFn<DataType, VariablesType> = Future<DataType> Function(
  VariablesType variables,
);

class MutationState<DataType, ErrorType, VariablesType> {
  final DataType? data;
  final ErrorType? error;
  final MutationFn<DataType, VariablesType> mutationFn;
  final DateTime updatedAt;

  MutationState({
    required this.mutationFn,
    this.data,
    this.error,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  MutationState<DataType, ErrorType, VariablesType> copyWith({
    DataType? data,
    ErrorType? error,
    DateTime? updatedAt,
    MutationFn<DataType, VariablesType>? mutationFn,
  }) {
    return MutationState<DataType, ErrorType, VariablesType>(
      mutationFn: mutationFn ?? this.mutationFn,
      data: data ?? this.data,
      error: error ?? this.error,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

class Mutation<DataType, ErrorType, VariablesType>
    extends StateNotifier<MutationState<DataType, ErrorType, VariablesType>>
    with Retryer<DataType, ErrorType> {
  final String key;
  final MutationFn<DataType, VariablesType> mutationFn;

  final RetryConfig retryConfig;

  Mutation(
    this.key,
    this.mutationFn, {
    this.retryConfig = DefaultConstants.retryConfig,
  })  : _dataController = StreamController.broadcast(),
        _errorController = StreamController.broadcast(),
        _mutationController = StreamController.broadcast(),
        super(
          MutationState<DataType, ErrorType, VariablesType>(
            mutationFn: mutationFn,
          ),
        );

  bool get isInactive => !hasListeners;
  bool get isMutating => _mutex.isLocked;
  bool get hasData => state.data != null;
  bool get hasError => state.error != null;

  DataType? get data => state.data;
  ErrorType? get error => state.error;
  Stream<DataType> get dataStream => _dataController.stream;
  Stream<ErrorType> get errorStream => _errorController.stream;
  Stream<VariablesType> get mutationStream => _mutationController.stream;

  final _mutex = Mutex();
  final StreamController<VariablesType> _mutationController;
  final StreamController<DataType> _dataController;
  final StreamController<ErrorType> _errorController;

  Future<void> _operate(VariablesType variables) {
    return _mutex.protect(() async {
      return await retryOperation(
        () {
          _mutationController.add(variables);
          return state.mutationFn(variables);
        },
        config: retryConfig,
        onSuccessful: (data) {
          state = state.copyWith(data: data);
          if (data is DataType) {
            _dataController.add(data);
          }
        },
        onFailed: (error) {
          state = state.copyWith(error: error);
          if (error is ErrorType) {
            _errorController.add(error);
          }
        },
      );
    });
  }

  Future<DataType?> mutate(
    VariablesType variables, {
    bool scheduleToQueue = false,
  }) {
    if (isMutating && !scheduleToQueue) {
      return Future.value(state.data);
    }
    return _operate(variables).then((_) => data);
  }

  void updateMutationFn(MutationFn<DataType, VariablesType> mutationFn) {
    if (mutationFn == state.mutationFn) return;
    state = state.copyWith(mutationFn: mutationFn, updatedAt: state.updatedAt);
  }

  void reset() {
    state = MutationState<DataType, ErrorType, VariablesType>(
      mutationFn: state.mutationFn,
    );
  }

  @override
  operator ==(Object other) {
    return identical(this, other) || (other is Mutation && key == other.key);
  }

  @override
  int get hashCode => key.hashCode;

  Mutation<NewDataType, NewErrorType, NewVariablesType>
      cast<NewDataType, NewErrorType, NewVariablesType>() {
    return this as Mutation<NewDataType, NewErrorType, NewVariablesType>;
  }
}
