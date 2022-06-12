import 'package:fl_query/models/query_job.dart';
import 'package:fl_query/query.dart';
import 'package:fl_query/query_bowl.dart';
import 'package:flutter/widgets.dart';

class QueryBuilder<T extends Object, Outside> extends StatefulWidget {
  final Function(BuildContext, Query<T, Outside>) builder;
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
  State<QueryBuilder<T, Outside>> createState() =>
      _QueryBuilderState<T, Outside>();
}

class _QueryBuilderState<T extends Object, Outside>
    extends State<QueryBuilder<T, Outside>> {
  late QueryBowl queryBowl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      queryBowl = QueryBowl.of(context);
      await queryBowl.fetchQuery<T, Outside>(
        widget.job,
        externalData: widget.externalData,
        onData: widget.onData,
        onError: widget.onError,
        mount: widget,
      );
    });
  }

  @override
  void didUpdateWidget(covariant oldWidget) {
    if (oldWidget.externalData != widget.externalData) {
      queryBowl = QueryBowl.of(context);
      // clearing up the old widget before adding the new updated one
      // so unmounted zombie widgets don't get piled up
      queryBowl.getQuery(widget.job.queryKey)?.unmount(oldWidget);
      queryBowl.fetchQuery(
        widget.job,
        externalData: widget.externalData,
        onData: widget.onData,
        onError: widget.onError,
        mount: widget,
      );
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    queryBowl.getQuery(widget.job.queryKey)?.unmount(widget);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    queryBowl = QueryBowl.of(context);
    final query = queryBowl.getQuery<T, Outside>(widget.job.queryKey);
    if (query == null) return Container();
    return widget.builder(context, query);
  }
}
