import 'package:fl_query/query.dart';
import 'package:fl_query/query_bowl.dart';
import 'package:flutter/widgets.dart';

class QueryBuilder<T> extends StatefulWidget {
  final Widget Function(BuildContext, Query<T>) builder;
  final QueryTaskFunction<T> task;
  final String queryKey;
  const QueryBuilder({
    required this.builder,
    required this.task,
    required this.queryKey,
    Key? key,
  }) : super(key: key);

  @override
  State<QueryBuilder<T>> createState() => _QueryBuilderState<T>();
}

class _QueryBuilderState<T> extends State<QueryBuilder<T>> {
  late Query<T> query;
  @override
  void initState() {
    super.initState();
    query = Query<T>(queryKey: widget.queryKey, task: widget.task);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await QueryBowl.of(context).fetchQuery(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final queryRT = QueryBowl.of(context).getQuery<T>(widget.queryKey) ?? query;
    return widget.builder(context, queryRT);
  }
}
