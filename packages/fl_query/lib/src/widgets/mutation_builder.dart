import 'dart:async';

import 'package:fl_query/src/collections/default_configs.dart';
import 'package:fl_query/src/collections/retry_config.dart';
import 'package:fl_query/src/core/client.dart';
import 'package:fl_query/src/core/mutation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/diagnostics.dart';

typedef MutationBuilderFn<DataType, ErrorType, KeyType, VariablesType> = Widget
    Function(
  BuildContext context,
  Mutation<DataType, ErrorType, KeyType, VariablesType> mutation,
);
typedef MutationOnDataFn<DataType, RecoveryType> = void Function(
  DataType data,
  RecoveryType? recoveryData,
);
typedef MutationOnErrorFn<ErrorType, RecoveryType> = void Function(
  ErrorType error,
  RecoveryType? recoveryData,
);
typedef MutationOnMutationFn<VariablesType, RecoveryType>
    = FutureOr<RecoveryType?> Function(
  VariablesType variables,
);

class MutationBuilder<DataType, ErrorType, KeyType, VariablesType, RecoveryType>
    extends StatefulWidget {
  final MutationFn<DataType, VariablesType> mutationFn;
  final ValueKey<KeyType> mutationKey;

  final RetryConfig retryConfig;

  final MutationOnDataFn<DataType, RecoveryType>? onData;
  final MutationOnErrorFn<ErrorType, RecoveryType>? onError;
  final MutationOnMutationFn<VariablesType, RecoveryType>? onMutate;

  // widget specific
  final MutationBuilderFn<DataType, ErrorType, KeyType, VariablesType> builder;
  final List<ValueKey>? refreshQueries;
  final List<ValueKey>? refreshInfiniteQueries;

  const MutationBuilder(
    this.mutationKey,
    this.mutationFn, {
    required this.builder,
    this.retryConfig = DefaultConstants.retryConfig,
    this.onData,
    this.onError,
    this.onMutate,
    this.refreshQueries,
    this.refreshInfiniteQueries,
    super.key,
  });

  @override
  State<
      MutationBuilder<DataType, ErrorType, KeyType, VariablesType,
          RecoveryType>> createState() => _MutationBuilderState<DataType,
      ErrorType, KeyType, VariablesType, RecoveryType>();
}

class _MutationBuilderState<DataType, ErrorType, KeyType, VariablesType,
        RecoveryType>
    extends State<
        MutationBuilder<DataType, ErrorType, KeyType, VariablesType,
            RecoveryType>> {
  Mutation<DataType, ErrorType, KeyType, VariablesType>? mutation;

  VoidCallback? removeListener;

  StreamSubscription<VariablesType>? mutationSubscription;
  StreamSubscription<DataType>? dataSubscription;
  StreamSubscription<ErrorType>? errorSubscription;

  RecoveryType? recoveryData;

  void update(_) {
    if (mounted) {
      setState(() {});
    }
  }

  void subscribeOnMutate() {
    if (widget.onMutate != null)
      mutationSubscription = mutation!.mutationStream.listen(
        (event) async {
          recoveryData = await widget.onMutate?.call(event);

          if (widget.onData != null) {
            dataSubscription?.cancel();
            subscribeOnData();
          }

          if (widget.onError != null) {
            errorSubscription?.cancel();
            subscribeOnError();
          }
        },
      );
  }

  void subscribeOnData() {
    if (widget.onData != null ||
        widget.refreshInfiniteQueries != null ||
        widget.refreshQueries != null)
      dataSubscription = mutation!.dataStream.listen(
        (event) {
          final data = widget.onData?.call(event, recoveryData);
          if (widget.refreshQueries != null && mounted) {
            QueryClient.of(context).refreshQueries(widget.refreshQueries!);
          }
          if (widget.refreshInfiniteQueries != null && mounted) {
            QueryClient.of(context)
                .refreshInfiniteQueries(widget.refreshInfiniteQueries!);
          }
          return data;
        },
      );
  }

  void subscribeOnError() {
    if (widget.onError != null)
      errorSubscription = mutation!.errorStream.listen(
        (event) {
          return widget.onError?.call(event, recoveryData);
        },
      );
  }

  Future<void> initialize() async {
    setState(() {
      mutation = QueryClient.of(context).createMutation(
        widget.mutationKey,
        widget.mutationFn,
        retryConfig: widget.retryConfig,
      );
      subscribeOnMutate();
      subscribeOnData();
      subscribeOnError();
      removeListener = mutation!.addListener(update);
    });
  }

  @override
  void initState() {
    super.initState();
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
  void didUpdateWidget(
    MutationBuilder<DataType, ErrorType, KeyType, VariablesType, RecoveryType>
        oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.mutationKey != widget.mutationKey) {
      mutationSubscription?.cancel();
      dataSubscription?.cancel();
      errorSubscription?.cancel();
      removeListener?.call();
      initialize();
      return;
    }
    if (oldWidget.mutationFn != widget.mutationFn) {
      mutation!.updateMutationFn(widget.mutationFn);
    }
    if (oldWidget.onMutate != widget.onMutate) {
      mutationSubscription?.cancel();
      subscribeOnMutate();
    }
    if (oldWidget.onData != widget.onData ||
        oldWidget.refreshQueries != widget.refreshQueries ||
        oldWidget.refreshInfiniteQueries != widget.refreshInfiniteQueries) {
      dataSubscription?.cancel();
      subscribeOnData();
      mutationSubscription?.cancel();
      subscribeOnMutate();
    }
    if (oldWidget.onError != widget.onError) {
      errorSubscription?.cancel();
      subscribeOnError();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (mutation == null) {
      return const SizedBox.shrink();
    }
    return widget.builder(context, mutation!);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<
              Mutation<DataType, ErrorType, KeyType, VariablesType>>(
          'mutation', mutation),
    );
    properties.add(
      DiagnosticsProperty<ValueKey<KeyType>>('mutationKey', widget.mutationKey),
    );
    properties.add(
      DiagnosticsProperty<MutationFn<DataType, VariablesType>>(
          'mutationFn', widget.mutationFn),
    );
    properties.add(
      DiagnosticsProperty<RetryConfig>('retryConfig', widget.retryConfig),
    );
    properties.add(
      DiagnosticsProperty<MutationOnDataFn<DataType, RecoveryType>>(
        'onData',
        widget.onData,
      ),
    );
    properties.add(
      DiagnosticsProperty<MutationOnErrorFn<ErrorType, RecoveryType>>(
        'onError',
        widget.onError,
      ),
    );
    properties.add(
      DiagnosticsProperty<MutationOnMutationFn<VariablesType, RecoveryType>>(
        'onMutation',
        widget.onMutate,
      ),
    );
    properties.add(
      DiagnosticsProperty<
          MutationBuilderFn<DataType, ErrorType, KeyType, VariablesType>>(
        'builder',
        widget.builder,
      ),
    );
  }
}