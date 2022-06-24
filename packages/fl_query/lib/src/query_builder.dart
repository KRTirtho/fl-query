import 'package:fl_query/src/models/query_job.dart';
import 'package:fl_query/src/query.dart';
import 'package:fl_query/src/query_bowl.dart';
import 'package:fl_query/src/utils.dart';
import 'package:flutter/widgets.dart';

class QueryBuilder<T extends Object, Outside> extends StatefulWidget {
  final Function(BuildContext context, Query<T, Outside> query) builder;
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
  late final ValueKey<String> uKey;
  Query<T, Outside>? query;

  @override
  void initState() {
    super.initState();
    uKey = ValueKey<String>(uuid.v4());
    WidgetsBinding.instance.addPostFrameCallback((_) => init());
  }

  void init([QueryBowl? bowl]) async {
    bowl ??= QueryBowl.of(context);
    query = bowl.addQuery<T, Outside>(
      Query<T, Outside>.fromOptions(
        widget.job,
        externalData: widget.externalData,
        queryBowl: QueryBowl.of(context),
      ),
      key: uKey,
      onData: widget.onData,
      onError: widget.onError,
    );
    final hasExternalDataChanged = query!.externalData != null &&
        query!.prevUsedExternalData != null &&
        !isShallowEqual(query!.externalData!, query!.prevUsedExternalData!);
    (query!.fetched && query!.refetchOnMount == true) || hasExternalDataChanged
        ? await query!.refetch()
        : await query!.fetch();
  }

  @override
  void didUpdateWidget(covariant oldWidget) {
    // re-init the query-builder when new queryJob is appended
    if (oldWidget.job.queryKey != widget.job.queryKey) {
      _queryDispose();
      init();
    } else if (oldWidget.externalData != null &&
        widget.externalData != null &&
        !isShallowEqual(oldWidget.externalData!, widget.externalData!)) {
      QueryBowl.of(context).fetchQuery(
        widget.job,
        externalData: widget.externalData,
        onData: widget.onData,
        onError: widget.onError,
        key: uKey,
      );
    } else {
      if (oldWidget.onData != widget.onData && oldWidget.onData != null) {
        query?.onDataListeners.remove(oldWidget.onData);
        if (widget.onData != null) query?.onDataListeners.add(widget.onData!);
      }
      if (oldWidget.onError != widget.onError && oldWidget.onError != null) {
        query?.onErrorListeners.remove(oldWidget.onError);
        if (widget.onError != null)
          query?.onErrorListeners.add(widget.onError!);
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  _queryDispose() {
    query?.unmount(uKey);
    if (widget.onData != null) query?.onDataListeners.remove(widget.onData);
    if (widget.onError != null) query?.onErrorListeners.remove(widget.onError);
  }

  @override
  void dispose() {
    _queryDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    queryBowl = QueryBowl.of(context);
    final latestQuery =
        queryBowl.getQuery<T, Outside>(widget.job.queryKey) ?? query;
    if (latestQuery == null) return Container();
    return widget.builder(context, latestQuery);
  }
}
