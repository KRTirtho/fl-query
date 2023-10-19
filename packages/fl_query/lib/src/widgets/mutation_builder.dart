import 'dart:async';

import 'package:fl_query/src/collections/jobs/mutation_job.dart';
import 'package:fl_query/src/collections/retry_config.dart';
import 'package:fl_query/src/core/client.dart';
import 'package:fl_query/src/core/mutation.dart';
import 'package:fl_query/src/widgets/mixins/rebuilder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef MutationBuilderFn<DataType, ErrorType, VariablesType> = Widget Function(
  BuildContext context,
  Mutation<DataType, ErrorType, VariablesType> mutation,
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

class MutationBuilder<DataType, ErrorType, VariablesType, RecoveryType>
    extends StatefulWidget {
  final MutationFn<DataType, VariablesType> mutationFn;
  final String mutationKey;

  final RetryConfig? retryConfig;

  final MutationOnDataFn<DataType, RecoveryType>? onData;
  final MutationOnErrorFn<ErrorType, RecoveryType>? onError;
  final MutationOnMutationFn<VariablesType, RecoveryType>? onMutate;

  // widget specific
  final MutationBuilderFn<DataType, ErrorType, VariablesType> builder;
  final List<String>? refreshQueries;
  final List<String>? refreshInfiniteQueries;

  const MutationBuilder(
    this.mutationKey,
    this.mutationFn, {
    required this.builder,
    this.retryConfig,
    this.onData,
    this.onError,
    this.onMutate,
    this.refreshQueries,
    this.refreshInfiniteQueries,
    super.key,
  });

  static MutationBuilder<DataType, ErrorType, VariablesType, RecoveryType>
      withJob<DataType, ErrorType, VariablesType, RecoveryType, ArgsType>({
    required MutationJob<DataType, ErrorType, VariablesType, RecoveryType,
            ArgsType>
        job,
    required MutationBuilderFn<DataType, ErrorType, VariablesType> builder,
    Key? key,
    MutationOnDataFn<DataType, RecoveryType>? onData,
    MutationOnErrorFn<ErrorType, RecoveryType>? onError,
    MutationOnMutationFn<VariablesType, RecoveryType>? onMutate,
    ArgsType? args,
  }) {
    return MutationBuilder<DataType, ErrorType, VariablesType, RecoveryType>(
      job.mutationKey,
      (variables) => job.task(variables, args),
      builder: builder,
      retryConfig: job.retryConfig,
      onData: onData,
      onError: onError,
      onMutate: onMutate,
      refreshQueries: job.refreshQueries,
      refreshInfiniteQueries: job.refreshInfiniteQueries,
      key: key,
    );
  }

  @override
  State<MutationBuilder<DataType, ErrorType, VariablesType, RecoveryType>>
      createState() => _MutationBuilderState<DataType, ErrorType, VariablesType,
          RecoveryType>();
}

class _MutationBuilderState<DataType, ErrorType, VariablesType, RecoveryType>
    extends State<
        MutationBuilder<DataType, ErrorType, VariablesType, RecoveryType>>
    with SafeRebuild {
  Mutation<DataType, ErrorType, VariablesType>? mutation;

  VoidCallback? removeListener;

  StreamSubscription<VariablesType>? mutationSubscription;
  StreamSubscription<DataType>? dataSubscription;
  StreamSubscription<ErrorType>? errorSubscription;

  RecoveryType? recoveryData;

  void subscribeOnMutate(QueryClient client) {
    if (widget.onMutate != null)
      mutationSubscription = mutation!.mutationStream.listen(
        (event) async {
          recoveryData = await widget.onMutate?.call(event);

          if (widget.onData != null) {
            dataSubscription?.cancel();
            subscribeOnData(client);
          }

          if (widget.onError != null) {
            errorSubscription?.cancel();
            subscribeOnError();
          }
        },
      );
  }

  void subscribeOnData(QueryClient client) {
    if (widget.onData != null ||
        widget.refreshInfiniteQueries != null ||
        widget.refreshQueries != null)
      dataSubscription = mutation!.dataStream.listen(
        (event) {
          final data = widget.onData?.call(event, recoveryData);
          if (widget.refreshQueries != null && mounted) {
            client.refreshQueries(widget.refreshQueries!);
          }
          if (widget.refreshInfiniteQueries != null && mounted) {
            client
                .refreshInfiniteQueriesAllPages(widget.refreshInfiniteQueries!);
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

  Future<void> initialize(QueryClient client) async {
    setState(() {
      _createMutation(client);
      subscribeOnMutate(client);
      subscribeOnData(client);
      subscribeOnError();
      removeListener = mutation!.addListener(rebuild);
    });
  }

  void _createMutation(QueryClient client) {
    mutation = client.createMutation(
      widget.mutationKey,
      widget.mutationFn,
      retryConfig: widget.retryConfig,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await initialize(QueryClient.of(context));
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
    MutationBuilder<DataType, ErrorType, VariablesType, RecoveryType> oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    final client = QueryClient.of(context);

    if (oldWidget.mutationKey != widget.mutationKey) {
      mutationSubscription?.cancel();
      dataSubscription?.cancel();
      errorSubscription?.cancel();
      removeListener?.call();
      initialize(client);
      return;
    }
    if (oldWidget.mutationFn != widget.mutationFn) {
      mutation!.updateMutationFn(widget.mutationFn);
    }
    if (oldWidget.onMutate != widget.onMutate) {
      mutationSubscription?.cancel();
      subscribeOnMutate(client);
    }
    if (oldWidget.onData != widget.onData ||
        oldWidget.refreshQueries != widget.refreshQueries ||
        oldWidget.refreshInfiniteQueries != widget.refreshInfiniteQueries) {
      dataSubscription?.cancel();
      subscribeOnData(client);
      mutationSubscription?.cancel();
      subscribeOnMutate(client);
    }
    if (oldWidget.onError != widget.onError) {
      errorSubscription?.cancel();
      subscribeOnError();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (mutation == null) {
      _createMutation(QueryClient.of(context));
    }
    return widget.builder(context, mutation!);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<Mutation<DataType, ErrorType, VariablesType>>(
          'mutation', mutation),
    );
    properties.add(
      DiagnosticsProperty<String>('mutationKey', widget.mutationKey),
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
          MutationBuilderFn<DataType, ErrorType, VariablesType>>(
        'builder',
        widget.builder,
      ),
    );
  }
}
