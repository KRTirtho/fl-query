import 'dart:async';

import 'package:fl_query/src/collections/default_configs.dart';
import 'package:fl_query/src/collections/json_config.dart';
import 'package:fl_query/src/collections/refresh_config.dart';
import 'package:fl_query/src/collections/retry_config.dart';
import 'package:fl_query/src/core/client.dart';
import 'package:fl_query/src/core/infinite_query.dart';
import 'package:flutter/material.dart';

typedef InfiniteQueryBuilderFn<DataType, ErrorType, KeyType, PageType> = Widget
    Function(
  BuildContext context,
  InfiniteQuery<DataType, ErrorType, KeyType, PageType> query,
);

class InfiniteQueryBuilder<DataType, ErrorType, KeyType, PageType>
    extends StatefulWidget {
  final InfiniteQueryFn<DataType, PageType> queryFn;
  final ValueKey<KeyType> queryKey;

  final PageType initialPage;
  final InfiniteQueryNextPage<DataType, PageType> nextPage;

  final RetryConfig retryConfig;
  final RefreshConfig refreshConfig;
  final JsonConfig<DataType>? jsonConfig;

  final ValueChanged<PageEvent<DataType, PageType>>? onData;
  final ValueChanged<PageEvent<ErrorType, PageType>>? onError;

  // widget specific
  final bool enabled;
  final InfiniteQueryBuilderFn<DataType, ErrorType, KeyType, PageType> builder;

  const InfiniteQueryBuilder(
    this.queryKey,
    this.queryFn, {
    required this.nextPage,
    required this.builder,
    required this.initialPage,
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
  State<InfiniteQueryBuilder<DataType, ErrorType, KeyType, PageType>>
      createState() =>
          _InfiniteQueryBuilderState<DataType, ErrorType, KeyType, PageType>();
}

class _InfiniteQueryBuilderState<DataType, ErrorType, KeyType, PageType>
    extends State<
        InfiniteQueryBuilder<DataType, ErrorType, KeyType, PageType>> {
  InfiniteQuery<DataType, ErrorType, KeyType, PageType>? query;

  VoidCallback? removeListener;

  StreamSubscription<PageEvent<DataType, PageType>>? dataSubscription;
  StreamSubscription<PageEvent<ErrorType, PageType>>? errorSubscription;

  void update(_) {
    if (mounted) setState(() {});
  }

  Future<void> initialize() async {
    setState(() {
      query = QueryClient.of(context).createInfiniteQuery(
        widget.queryKey,
        widget.queryFn,
        initialParam: widget.initialPage,
        nextPage: widget.nextPage,
        retryConfig: widget.retryConfig,
        refreshConfig: widget.refreshConfig,
        jsonConfig: widget.jsonConfig,
      );

      if (widget.onData != null)
        dataSubscription = query!.dataStream.listen(widget.onData);
      if (widget.onError != null)
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initialize();
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
  void didUpdateWidget(oldWidget) {
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
    if (oldWidget.nextPage != widget.nextPage) {
      query!.updateNextPageFn(widget.nextPage);
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
}
