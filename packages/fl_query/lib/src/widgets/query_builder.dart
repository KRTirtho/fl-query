import 'dart:async';

import 'package:fl_query/src/collections/default_configs.dart';
import 'package:fl_query/src/collections/json_config.dart';
import 'package:fl_query/src/collections/refresh_config.dart';
import 'package:fl_query/src/collections/retry_config.dart';
import 'package:fl_query/src/core/client.dart';
import 'package:fl_query/src/core/query.dart';
import 'package:flutter/material.dart';

typedef QueryBuilderFn<DataType, ErrorType, KeyType> = Widget Function(
  BuildContext context,
  Query<DataType, ErrorType, KeyType> query,
);

class QueryBuilder<DataType, ErrorType, KeyType> extends StatefulWidget {
  final QueryFn<DataType> queryFn;
  final ValueKey<KeyType> queryKey;

  final QueryBuilderFn builder;
  final DataType? initial;

  final RetryConfig retryConfig;
  final RefreshConfig refreshConfig;
  final JsonConfig<DataType>? jsonConfig;

  final ValueChanged<DataType>? onData;
  final ValueChanged<ErrorType>? onError;

  // widget specific
  final bool enabled;

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
  });

  @override
  State<QueryBuilder<DataType, ErrorType, KeyType>> createState() =>
      _QueryBuilderState<DataType, ErrorType, KeyType>();
}

class _QueryBuilderState<DataType, ErrorType, KeyType>
    extends State<QueryBuilder<DataType, ErrorType, KeyType>> {
  Query<DataType, ErrorType, KeyType>? query;

  VoidCallback? removeListener;

  StreamSubscription<DataType>? dataSubscription;
  StreamSubscription<ErrorType>? errorSubscription;

  void update(_) {
    setState(() {});
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

      dataSubscription = query!.dataStream.listen(widget.onData);
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
    QueryBuilder<DataType, ErrorType, KeyType> oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.queryKey != widget.queryKey) {
      dataSubscription?.cancel();
      errorSubscription?.cancel();
      removeListener?.call();
      initialize();
      return;
    }
    if (oldWidget.queryFn != widget.queryFn) {
      query!.updateQueryFn(widget.queryFn);
    }
    if (oldWidget.onData != widget.onData) {
      dataSubscription?.cancel();
      dataSubscription = query!.dataStream.listen(widget.onData);
    }
    if (oldWidget.onError != widget.onError) {
      errorSubscription?.cancel();
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
}
