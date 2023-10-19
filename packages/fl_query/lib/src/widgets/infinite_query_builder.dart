import 'dart:async';

import 'package:fl_query/src/collections/jobs/infinite_query_job.dart';
import 'package:fl_query/src/collections/json_config.dart';
import 'package:fl_query/src/collections/refresh_config.dart';
import 'package:fl_query/src/collections/retry_config.dart';
import 'package:fl_query/src/core/client.dart';
import 'package:fl_query/src/core/infinite_query.dart';
import 'package:fl_query/src/widgets/mixins/rebuilder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef InfiniteQueryBuilderFn<DataType, ErrorType, PageType> = Widget Function(
  BuildContext context,
  InfiniteQuery<DataType, ErrorType, PageType> query,
);

class InfiniteQueryBuilder<DataType, ErrorType, PageType>
    extends StatefulWidget {
  final InfiniteQueryFn<DataType, PageType> queryFn;
  final String queryKey;

  final PageType initialPage;
  final InfiniteQueryNextPage<DataType, PageType> nextPage;

  final RetryConfig? retryConfig;
  final RefreshConfig? refreshConfig;
  final JsonConfig<DataType>? jsonConfig;

  final ValueChanged<PageEvent<DataType, PageType>>? onData;
  final ValueChanged<PageEvent<ErrorType, PageType>>? onError;

  /// Toggle to fetch data on initial load or not
  ///
  /// This is useful when you want to fetch data manually after certain action
  ///
  /// Once user manually fetch data, this will be set to true internally
  final bool enabled;
  final InfiniteQueryBuilderFn<DataType, ErrorType, PageType> builder;

  const InfiniteQueryBuilder(
    this.queryKey,
    this.queryFn, {
    required this.nextPage,
    required this.builder,
    required this.initialPage,
    this.retryConfig,
    this.refreshConfig,
    this.jsonConfig,
    this.onData,
    this.onError,
    this.enabled = true,
    super.key,
  }) : assert(
          (jsonConfig != null && enabled) || jsonConfig == null,
          'jsonConfig is only supported when enabled is true',
        );

  static InfiniteQueryBuilder<DataType, ErrorType, PageType>
      withJob<DataType, ErrorType, PageType, ArgsType>({
    required InfiniteQueryJob<DataType, ErrorType, PageType, ArgsType> job,
    required InfiniteQueryBuilderFn<DataType, ErrorType, PageType> builder,
    ValueChanged<PageEvent<DataType, PageType>>? onData,
    ValueChanged<PageEvent<ErrorType, PageType>>? onError,
    Key? key,
    ArgsType? args,
  }) {
    return InfiniteQueryBuilder<DataType, ErrorType, PageType>(
      job.queryKey,
      (page) => job.task(page, args),
      builder: builder,
      initialPage: job.initialPage,
      nextPage: job.nextPage,
      retryConfig: job.retryConfig,
      refreshConfig: job.refreshConfig,
      jsonConfig: job.jsonConfig,
      onData: onData,
      onError: onError,
      enabled: job.enabled,
      key: key,
    );
  }

  @override
  State<InfiniteQueryBuilder<DataType, ErrorType, PageType>> createState() =>
      _InfiniteQueryBuilderState<DataType, ErrorType, PageType>();
}

class _InfiniteQueryBuilderState<DataType, ErrorType, PageType>
    extends State<InfiniteQueryBuilder<DataType, ErrorType, PageType>>
    with SafeRebuild {
  InfiniteQuery<DataType, ErrorType, PageType>? query;

  VoidCallback? removeListener;

  StreamSubscription<PageEvent<DataType, PageType>>? dataSubscription;
  StreamSubscription<PageEvent<ErrorType, PageType>>? errorSubscription;

  Future<void> initialize(QueryClient client) async {
    setState(() {
      _createQuery(client);

      if (widget.onData != null)
        dataSubscription = query!.dataStream.listen(widget.onData);
      if (widget.onError != null)
        errorSubscription = query!.errorStream.listen(widget.onError);

      removeListener = query!.addListener(rebuild);
    });
    if (widget.enabled) {
      await query!.fetch();
    }
  }

  void _createQuery(QueryClient client) {
    query = client.createInfiniteQuery(
      widget.queryKey,
      widget.queryFn,
      initialParam: widget.initialPage,
      nextPage: widget.nextPage,
      retryConfig: widget.retryConfig,
      refreshConfig: widget.refreshConfig,
      jsonConfig: widget.jsonConfig,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initialize(QueryClient.of(context));
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
      initialize(QueryClient.of(context));
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
      _createQuery(QueryClient.of(context));
    }
    return widget.builder(context, query!);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<
        InfiniteQueryBuilderFn<DataType, ErrorType, PageType>>(
      'builder',
      widget.builder,
    ));
    properties.add(DiagnosticsProperty<InfiniteQueryFn<DataType, PageType>>(
      'queryFn',
      widget.queryFn,
    ));
    properties
        .add(DiagnosticsProperty<InfiniteQueryNextPage<DataType, PageType>>(
      'nextPage',
      widget.nextPage,
    ));
    properties.add(DiagnosticsProperty<PageType>(
      'initialPage',
      widget.initialPage,
    ));
    properties.add(DiagnosticsProperty<RetryConfig>(
      'retryConfig',
      widget.retryConfig,
    ));
    properties.add(DiagnosticsProperty<RefreshConfig>(
      'refreshConfig',
      widget.refreshConfig,
    ));
    properties.add(DiagnosticsProperty<JsonConfig<DataType>>(
      'jsonConfig',
      widget.jsonConfig,
    ));
    properties
        .add(DiagnosticsProperty<ValueChanged<PageEvent<DataType, PageType>>>(
      'onData',
      widget.onData,
    ));
    properties
        .add(DiagnosticsProperty<ValueChanged<PageEvent<ErrorType, PageType>>>(
      'onError',
      widget.onError,
    ));
    properties.add(DiagnosticsProperty<bool>(
      'enabled',
      widget.enabled,
    ));
    properties.add(DiagnosticsProperty<String>(
      'queryKey',
      widget.queryKey,
    ));
  }
}
