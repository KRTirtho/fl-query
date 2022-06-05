import 'package:fl_query/models/query_job.dart';
import 'package:fl_query/query.dart';
import 'package:fl_query/query_bowl.dart';
import 'package:flutter/widgets.dart';

class QueryBuilder<T extends Object, Outside> extends StatefulWidget {
  final Function(BuildContext, Query<T, Outside>) builder;
  final QueryJob<T, Outside> job;
  final Outside externalData;

  const QueryBuilder({
    required this.job,
    required this.externalData,
    required this.builder,
    Key? key,
  }) : super(key: key);

  @override
  State<QueryBuilder<T, Outside>> createState() =>
      _QueryBuilderState<T, Outside>();
}

class _QueryBuilderState<T extends Object, Outside>
    extends State<QueryBuilder<T, Outside>> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await QueryBowl.of(context).fetchQuery<T, Outside>(widget.job,
          externalData: widget.externalData);
    });
  }

  @override
  void didUpdateWidget(covariant oldWidget) {
    if (oldWidget.externalData != widget.externalData) {
      QueryBowl.of(context)
          .fetchQuery(widget.job, externalData: widget.externalData);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final query =
        QueryBowl.of(context).getQuery<T, Outside>(widget.job.queryKey);
    if (query == null) return Container();
    return widget.builder(context, query);
  }
}
