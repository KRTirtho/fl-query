import 'dart:async';

import 'package:fl_query/src/collections/default_configs.dart';
import 'package:fl_query/src/collections/json_config.dart';
import 'package:fl_query/src/collections/refresh_config.dart';
import 'package:fl_query/src/collections/retry_config.dart';
import 'package:fl_query/src/core/client.dart';
import 'package:fl_query/src/core/query.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/diagnostics.dart';

typedef QueryBuilderFn<DataType, ErrorType> = Widget Function(
  BuildContext context,
  Query<DataType, ErrorType> query,
);

class QueryBuilder<DataType, ErrorType> extends StatefulWidget {
  final QueryFn<DataType> queryFn;
  final String queryKey;

  final DataType? initial;

  final RetryConfig retryConfig;
  final RefreshConfig refreshConfig;
  final JsonConfig<DataType>? jsonConfig;

  final ValueChanged<DataType>? onData;
  final ValueChanged<ErrorType>? onError;

  // widget specific
  final bool enabled;
  final QueryBuilderFn<DataType, ErrorType> builder;

  const QueryBuilder(
    this.queryKey,
    this.queryFn, {
    required this.builder,
    this.initial,
    this.retryConfig = DefaultConstants.retryConfig,
    this.refreshConfig = DefaultConstants.refreshConfig,
    this.jsonConfig,
    this.onData,
    this.onError,
    this.enabled = true,
    super.key,
  }) : assert(
          (jsonConfig != null && enabled) || jsonConfig == null,
          'jsonConfig is only supported when enabled is true',
        );

  @override
  State<QueryBuilder<DataType, ErrorType>> createState() =>
      _QueryBuilderState<DataType, ErrorType>();
}

class _QueryBuilderState<DataType, ErrorType>
    extends State<QueryBuilder<DataType, ErrorType>> {
  Query<DataType, ErrorType>? query;

  VoidCallback? removeListener;

  StreamSubscription<DataType>? dataSubscription;
  StreamSubscription<ErrorType>? errorSubscription;

  void update(_) {
    if (mounted) setState(() {});
  }

  Future<void> initialize() async {
    setState(() {
      query = QueryClient.of(context).createQuery(
        widget.queryKey,
        widget.queryFn,
        initial: widget.initial,
        retryConfig: widget.retryConfig,
        refreshConfig: widget.refreshConfig,
        jsonConfig: widget.jsonConfig,
      );

      if (widget.onData != null)
        dataSubscription = query!.dataStream.listen(widget.onData);
      if (widget.onData != null)
        errorSubscription = query!.errorStream.listen(widget.onError);

      removeListener = query!.addListener(update);
    });
    if (widget.enabled) {
      await query!.fetch();
    }
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
    dataSubscription?.cancel();
    errorSubscription?.cancel();
    removeListener?.call();
    super.dispose();
  }

  @override
  void didUpdateWidget(
    QueryBuilder<DataType, ErrorType> oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.queryKey != widget.queryKey) {
      dataSubscription?.cancel();
      errorSubscription?.cancel();
      removeListener?.call();
      initialize();
      return;
    } else if (oldWidget.enabled != widget.enabled && widget.enabled) {
      query!.fetch();
    }
    if (oldWidget.queryFn != widget.queryFn) {
      query!.updateQueryFn(widget.queryFn);
    }
    if (oldWidget.onData != widget.onData) {
      dataSubscription?.cancel();
      if (widget.onData != null)
        dataSubscription = query!.dataStream.listen(widget.onData);
    }
    if (oldWidget.onError != widget.onError) {
      errorSubscription?.cancel();
      if (widget.onError != null)
        errorSubscription = query!.errorStream.listen(widget.onError);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (query == null) {
      return const SizedBox.shrink();
    }
    return widget.builder(context, query!);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<Query<DataType, ErrorType>>('query', query),
    );
    properties.add(
      DiagnosticsProperty<String>('queryKey', widget.queryKey),
    );
    properties.add(
      DiagnosticsProperty<QueryBuilderFn<DataType, ErrorType>>(
          'builder', widget.builder),
    );
    properties.add(DiagnosticsProperty<DataType>('initial', widget.initial));
    properties.add(
      DiagnosticsProperty<RetryConfig>('retryConfig', widget.retryConfig),
    );
    properties.add(
      DiagnosticsProperty<RefreshConfig>(
        'refreshConfig',
        widget.refreshConfig,
      ),
    );
    properties.add(
      DiagnosticsProperty<JsonConfig<DataType>>(
        'jsonConfig',
        widget.jsonConfig,
      ),
    );
    properties.add(
      DiagnosticsProperty<ValueChanged<DataType>>('onData', widget.onData),
    );
    properties.add(
      DiagnosticsProperty<ValueChanged<ErrorType>>('onError', widget.onError),
    );
    properties.add(DiagnosticsProperty<bool>('enabled', widget.enabled));
  }
}
