import 'package:fl_query/src/models/query_job.dart';
import 'package:fl_query/src/query.dart';
import 'package:fl_query/src/query_bowl.dart';
import 'package:fl_query/src/utils.dart';
import 'package:flutter/cupertino.dart';

class QueryBuilder<T extends Object, Outside> extends StatefulWidget {
  final Widget Function(BuildContext context, Query<T, Outside> query) builder;
  final QueryJob<T, Outside> job;
  final Outside externalData;

  /// Called when the query returns new data, on query
  /// refetch or query gets expired
  final QueryListener<T>? onData;

  /// Called when the query returns error
  final QueryListener<dynamic>? onError;

  const QueryBuilder({
    required this.job,
    required this.externalData,
    required this.builder,
    this.onData,
    this.onError,
    Key? key,
  }) : super(key: key);

  @override
  _QueryBuilderState<T, Outside> createState() =>
      _QueryBuilderState<T, Outside>();
}

class _QueryBuilderState<T extends Object, Outside>
    extends State<QueryBuilder<T, Outside>> {
  Query<T, Outside>? query;
  late final ValueKey<String> uKey;

  @override
  void initState() {
    super.initState();

    uKey = ValueKey<String>(uuid.v4());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      init();

      QueryBowl.of(context).onQueriesUpdate<T, Outside>(
        (query) {
          if (query.queryKey != widget.job.queryKey) return;
          if (mounted)
            setState(() {
              this.query = query;
            });
        },
      );
    });
  }

  void init([T? previousData]) async {
    final bowl = QueryBowl.of(context);
    query = bowl.addQuery<T, Outside>(
      widget.job,
      externalData: widget.externalData,
      previousData: previousData,
      key: uKey,
      onData: widget.onData,
      onError: widget.onError,
    );

    final hasExternalDataChanged = query!.externalData != null &&
        query!.prevUsedExternalData != null &&
        !isShallowEqual(
          query!.externalData!,
          query!.prevUsedExternalData!,
        );

    if (query!.fetched && hasExternalDataChanged) {
      await query!.refetch();
    } else if (!query!.fetched) {
      await query!.fetch();
    }
  }

  @override
  void didUpdateWidget(covariant oldWidget) {
    final bowl = QueryBowl.of(context);
    final hasOnErrorChanged =
        oldWidget.onError != widget.onError && oldWidget.onError != null;
    final hasOnDataChanged =
        oldWidget.onData != widget.onData && oldWidget.onData != null;

    // re-init the query-builder when new queryJob is appended
    if (oldWidget.job.queryKey != widget.job.queryKey) {
      _queryDispose();

      /// setting the new query's initial data as prev query's data
      /// when [job.keepPreviousData] is true and both are dynamic
      if (oldWidget.job.isDynamic &&
          widget.job.isDynamic &&
          oldWidget.job.keepPreviousData == true &&
          widget.job.keepPreviousData == true) {
        init(query?.data);
      } else {
        init();
      }
    } else if (oldWidget.externalData != null &&
        widget.externalData != null &&
        !isShallowEqual(oldWidget.externalData!, widget.externalData!)) {
      if (widget.job.refetchOnExternalDataChange ??
          bowl.refetchOnExternalDataChange) {
        bowl.fetchQuery(
          widget.job,
          externalData: widget.externalData,
          onData: widget.onData,
          onError: widget.onError,
          key: uKey,
        );
      } else {
        bowl
            .getQuery(widget.job.queryKey)
            ?.setExternalData(widget.externalData);
      }
      if (hasOnDataChanged) query?.removeDataListener(oldWidget.onData!);
      if (hasOnErrorChanged) query?.removeErrorListener(oldWidget.onError!);
    } else {
      if (hasOnDataChanged) {
        query?.removeDataListener(oldWidget.onData!);
        if (widget.onData != null) query?.addDataListener(widget.onData!);
      }
      if (hasOnErrorChanged) {
        query?.removeErrorListener(oldWidget.onError!);
        if (widget.onError != null) query?.addErrorListener(widget.onError!);
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  _queryDispose() {
    query?.unmount(uKey);
    if (widget.onData != null) query?.removeDataListener(widget.onData!);
    if (widget.onError != null) query?.removeErrorListener(widget.onError!);
  }

  @override
  void dispose() {
    _queryDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (query == null) return Container();
    return widget.builder(context, query!);
  }
}
