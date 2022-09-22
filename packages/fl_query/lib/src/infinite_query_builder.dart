// ignore_for_file: invalid_use_of_protected_member

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
  final InfiniteQueryListeners<T, PageParam>? onData;
  final InfiniteQueryListeners<dynamic, PageParam>? onError;

  InfiniteQueryBuilder({
    required this.job,
    required this.builder,
    required this.externalData,
    this.onData,
    this.onError,
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      init();
      QueryBowl.of(context).onInfiniteQueriesUpdate<T, Outside, PageParam>(
        (infiniteQuery) {
          if (infiniteQuery.queryKey != widget.job.queryKey) return;
          if (mounted)
            setState(() {
              this.infiniteQuery = infiniteQuery;
            });
        },
      );
    });
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
          infiniteQuery!.externalData!,
          infiniteQuery!.prevUsedExternalData!,
        );

    if (infiniteQuery!.fetched && hasExternalDataChanged) {
      await infiniteQuery!.refetchPages();
    } else if (!infiniteQuery!.fetched) {
      await infiniteQuery!.fetch();
    }
  }

  @override
  void didUpdateWidget(covariant oldWidget) {
    final hasOnErrorChanged =
        oldWidget.onError != widget.onError && oldWidget.onError != null;
    final hasOnDataChanged =
        oldWidget.onData != widget.onData && oldWidget.onData != null;

    // re-init the query-builder when new queryJob is appended
    if (oldWidget.job.queryKey != widget.job.queryKey) {
      _infiniteQueryDispose();
      init();

      /// setting the new query's initial data as prev query's data
      /// when [job.keepPreviousData] is true and both are dynamic
      // if (oldWidget.job.isDynamic &&
      //     widget.job.isDynamic &&
      //     oldWidget.job.keepPreviousData == true &&
      //     widget.job.keepPreviousData == true) {
      //   init(infiniteQuery?.pages);
      // } else {
      // init();
      // }
    } else if (oldWidget.externalData != null &&
        widget.externalData != null &&
        !isShallowEqual(oldWidget.externalData!, widget.externalData!)) {
      if (widget.job.refetchOnExternalDataChange ??
          queryBowl.refetchOnExternalDataChange) {
        QueryBowl.of(context).addInfiniteQuery(
          widget.job,
          externalData: widget.externalData,
          key: uKey,
          onData: widget.onData,
          onError: widget.onError,
        )..refetchPages();
      } else {
        QueryBowl.of(context)
            .getQuery(widget.job.queryKey)
            ?.setExternalData(widget.externalData);
      }
      if (hasOnDataChanged)
        infiniteQuery?.removeDataListener(oldWidget.onData!);
      if (hasOnErrorChanged)
        infiniteQuery?.removeErrorListener(oldWidget.onError!);
    } else {
      if (hasOnDataChanged) {
        infiniteQuery?.removeDataListener(oldWidget.onData!);
        if (widget.onData != null)
          infiniteQuery?.addDataListener(widget.onData!);
      }
      if (hasOnErrorChanged) {
        infiniteQuery?.removeErrorListener(oldWidget.onError!);
        if (widget.onError != null)
          infiniteQuery?.addErrorListener(widget.onError!);
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  _infiniteQueryDispose() {
    infiniteQuery?.unmount(uKey);
    if (widget.onData != null)
      infiniteQuery?.removeDataListener(widget.onData!);
    if (widget.onError != null)
      infiniteQuery?.removeErrorListener(widget.onError!);
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
