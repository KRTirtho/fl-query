import 'package:fl_query/query.dart';
import 'package:fl_query/query_bowl.dart';
import 'package:flutter/widgets.dart';

class QueryBuilder<T> extends StatefulWidget {
  final Widget Function(BuildContext, Query<T>) builder;
  final QueryTaskFunction<T> task;
  final String queryKey;
  final Duration? staleTime;
  final int retries;
  final T? initialData;
  final Duration retryDelay;

  final QueryListener<T>? onData;
  final QueryListener<dynamic>? onError;

  const QueryBuilder({
    required this.builder,
    required this.task,
    required this.queryKey,
    this.initialData,
    this.staleTime,
    this.retryDelay = const Duration(milliseconds: 200),
    this.retries = 3,
    this.onData,
    this.onError,
    Key? key,
  }) : super(key: key);

  @override
  State<QueryBuilder<T>> createState() => _QueryBuilderState<T>();
}

class _QueryBuilderState<T> extends State<QueryBuilder<T>> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await QueryBowl.of(context).fetchQuery(Query<T>(
        queryKey: widget.queryKey,
        task: widget.task,
        staleTime: widget.staleTime ?? QueryBowl.of(context).staleTime,
        retries: widget.retries,
        initialData: widget.initialData,
        retryDelay: widget.retryDelay,
        onData: widget.onData,
        onError: widget.onError,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = QueryBowl.of(context).getQuery<T>(widget.queryKey);
    if (query == null) return Container();
    return widget.builder(context, query);
  }
}
