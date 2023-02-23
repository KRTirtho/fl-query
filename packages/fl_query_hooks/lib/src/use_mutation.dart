import 'dart:async';

import 'package:fl_query/fl_query.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/diagnostics.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

Mutation<DataType, ErrorType, VariablesType>
    useMutation<DataType, ErrorType, VariablesType, RecoveryType>(
  String mutationKey,
  MutationFn<DataType, VariablesType> mutationFn, {
  RetryConfig retryConfig = DefaultConstants.retryConfig,
  MutationOnDataFn<DataType, RecoveryType>? onData,
  MutationOnErrorFn<ErrorType, RecoveryType>? onError,
  MutationOnMutationFn<VariablesType, RecoveryType>? onMutate,
  List<String>? refreshQueries,
  List<String>? refreshInfiniteQueries,
  List<Object?>? keys,
}) {
  return use(
    UseMutation(
      mutationKey,
      mutationFn,
      retryConfig: retryConfig,
      onData: onData,
      onError: onError,
      onMutate: onMutate,
      refreshQueries: refreshQueries,
      refreshInfiniteQueries: refreshInfiniteQueries,
      keys: keys,
    ),
  );
}

class UseMutation<DataType, ErrorType, VariablesType, RecoveryType>
    extends Hook<Mutation<DataType, ErrorType, VariablesType>> {
  final MutationFn<DataType, VariablesType> mutationFn;
  final String mutationKey;

  final RetryConfig retryConfig;

  final MutationOnDataFn<DataType, RecoveryType>? onData;
  final MutationOnErrorFn<ErrorType, RecoveryType>? onError;
  final MutationOnMutationFn<VariablesType, RecoveryType>? onMutate;

  // hook specific
  final List<String>? refreshQueries;
  final List<String>? refreshInfiniteQueries;

  const UseMutation(
    this.mutationKey,
    this.mutationFn, {
    this.retryConfig = DefaultConstants.retryConfig,
    this.onData,
    this.onError,
    this.onMutate,
    this.refreshQueries,
    this.refreshInfiniteQueries,
    super.keys,
  });

  @override
  createState() =>
      _UseMutationState<DataType, ErrorType, VariablesType, RecoveryType>();
}

class _UseMutationState<DataType, ErrorType, VariablesType, RecoveryType>
    extends HookState<Mutation<DataType, ErrorType, VariablesType>,
        UseMutation<DataType, ErrorType, VariablesType, RecoveryType>> {
  Mutation<DataType, ErrorType, VariablesType>? mutation;

  VoidCallback? removeListener;

  StreamSubscription<VariablesType>? mutationSubscription;
  StreamSubscription<DataType>? dataSubscription;
  StreamSubscription<ErrorType>? errorSubscription;

  RecoveryType? recoveryData;

  void rebuild([_]) {
    setState(() {});
  }

  void subscribeOnMutate() {
    if (hook.onMutate != null)
      mutationSubscription = mutation!.mutationStream.listen(
        (event) async {
          recoveryData = await hook.onMutate?.call(event);

          if (hook.onData != null) {
            dataSubscription?.cancel();
            subscribeOnData();
          }

          if (hook.onError != null) {
            errorSubscription?.cancel();
            subscribeOnError();
          }
        },
      );
  }

  void subscribeOnData() {
    if (hook.onData != null ||
        hook.refreshInfiniteQueries != null ||
        hook.refreshQueries != null)
      dataSubscription = mutation!.dataStream.listen(
        (event) {
          final data = hook.onData?.call(event, recoveryData);
          if (hook.refreshQueries != null) {
            QueryClient.of(context).refreshQueries(hook.refreshQueries!);
          }
          if (hook.refreshInfiniteQueries != null) {
            QueryClient.of(context)
                .refreshInfiniteQueries(hook.refreshInfiniteQueries!);
          }
          return data;
        },
      );
  }

  void subscribeOnError() {
    if (hook.onError != null)
      errorSubscription = mutation!.errorStream.listen(
        (event) {
          return hook.onError?.call(event, recoveryData);
        },
      );
  }

  Future<void> initialize() async {
    setState(() {
      _createMutation();
      subscribeOnMutate();
      subscribeOnData();
      subscribeOnError();
      removeListener = mutation!.addListener(rebuild);
    });
  }

  void _createMutation() {
    mutation = QueryClient.of(context).createMutation(
      hook.mutationKey,
      hook.mutationFn,
      retryConfig: hook.retryConfig,
    );
  }

  @override
  void initHook() {
    super.initHook();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await initialize();
    });
  }

  @override
  void dispose() {
    mutationSubscription?.cancel();
    dataSubscription?.cancel();
    errorSubscription?.cancel();
    removeListener?.call();
    super.dispose();
  }

  @override
  void didUpdateHook(oldHook) {
    super.didUpdateHook(oldHook);

    if (oldHook.mutationKey != hook.mutationKey) {
      mutationSubscription?.cancel();
      dataSubscription?.cancel();
      errorSubscription?.cancel();
      removeListener?.call();
      initialize();
      return;
    }
    if (oldHook.mutationFn != hook.mutationFn) {
      mutation!.updateMutationFn(hook.mutationFn);
    }
    if (oldHook.onMutate != hook.onMutate) {
      mutationSubscription?.cancel();
      subscribeOnMutate();
    }
    if (oldHook.onData != hook.onData ||
        oldHook.refreshQueries != hook.refreshQueries ||
        oldHook.refreshInfiniteQueries != hook.refreshInfiniteQueries) {
      dataSubscription?.cancel();
      subscribeOnData();
      mutationSubscription?.cancel();
      subscribeOnMutate();
    }
    if (oldHook.onError != hook.onError) {
      errorSubscription?.cancel();
      subscribeOnError();
    }
  }

  @override
  build(BuildContext context) {
    if (mutation == null) {
      _createMutation();
    }
    return mutation!;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<Mutation<DataType, ErrorType, VariablesType>>(
          'mutation', mutation),
    );
    properties.add(
      DiagnosticsProperty<String>('mutationKey', hook.mutationKey),
    );
    properties.add(
      DiagnosticsProperty<MutationFn<DataType, VariablesType>>(
          'mutationFn', hook.mutationFn),
    );
    properties.add(
      DiagnosticsProperty<RetryConfig>('retryConfig', hook.retryConfig),
    );
    properties.add(
      DiagnosticsProperty<MutationOnDataFn<DataType, RecoveryType>>(
        'onData',
        hook.onData,
      ),
    );
    properties.add(
      DiagnosticsProperty<MutationOnErrorFn<ErrorType, RecoveryType>>(
        'onError',
        hook.onError,
      ),
    );
    properties.add(
      DiagnosticsProperty<MutationOnMutationFn<VariablesType, RecoveryType>>(
        'onMutation',
        hook.onMutate,
      ),
    );
  }
}
