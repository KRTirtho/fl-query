import 'package:fl_query/src/infinite_query.dart';
import 'package:fl_query/src/models/infinite_query_job.dart';
import 'package:fl_query/src/query_bowl.dart';
import 'package:fl_query/src/utils.dart';
import 'package:flutter/widgets.dart';

class InfiniteQueryBuilder<T extends Object, Outside, PageParam extends Object>
    extends StatefulWidget {
  final Function(
    BuildContext context,
    InfiniteQuery<T, Outside, PageParam> query,
  ) builder;
  final InfiniteQueryJob<T, Outside, PageParam> job;
  final Outside externalData;
  InfiniteQueryBuilder({
    required this.job,
    required this.builder,
    required this.externalData,
    Key? key,
  }) : super(key: key);

  @override
  State<InfiniteQueryBuilder<T, Outside, PageParam>> createState() =>
      _InfiniteQueryBuilderState<T, Outside, PageParam>();
}

class _InfiniteQueryBuilderState<T extends Object, Outside,
        PageParam extends Object>
    extends State<InfiniteQueryBuilder<T, Outside, PageParam>> {
  InfiniteQuery<T, Outside, PageParam>? infiniteQuery;
  late QueryBowl queryBowl;
  late final ValueKey<String> uKey;

  @override
  void initState() {
    super.initState();
    uKey = ValueKey<String>(uuid.v4());
    WidgetsBinding.instance.addPostFrameCallback((_) => init());
  }

  void init([T? previousData]) async {
    final bowl = QueryBowl.of(context);
    infiniteQuery = bowl.addInfiniteQuery<T, Outside, PageParam>(
      widget.job,
      externalData: widget.externalData,
      key: uKey,
    );
    final hasExternalDataChanged = infiniteQuery!.externalData != null &&
        infiniteQuery!.prevUsedExternalData != null &&
        !isShallowEqual(
            infiniteQuery!.externalData!, infiniteQuery!.prevUsedExternalData!);
    if (infiniteQuery!.fetched && hasExternalDataChanged) {
      await infiniteQuery!.refetch();
    } else if (!infiniteQuery!.fetched) {
      await infiniteQuery!.fetch();
    }
  }

  @override
  Widget build(BuildContext context) {
    queryBowl = QueryBowl.of(context);
    final latestInfiniteQuery = queryBowl
            .getInfiniteQuery<T, Outside, PageParam>(widget.job.queryKey) ??
        infiniteQuery;
    if (latestInfiniteQuery == null) return Container();
    return widget.builder(context, latestInfiniteQuery);
  }
}
