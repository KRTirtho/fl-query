import 'dart:async';

import 'package:fl_query/models/query_job.dart';
import 'package:fl_query/query.dart';
import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';

class QueryBowlScope extends StatefulWidget {
  final Widget child;
  final Duration staleTime;
  final Duration cacheTime;

  /// used for periodically checking if any query got stale.
  /// If none is supplied then half of the value of staleTime is used
  final Duration refreshInterval;
  const QueryBowlScope({
    required this.child,
    this.staleTime = const Duration(milliseconds: 500),
    this.cacheTime = const Duration(minutes: 5),
    this.refreshInterval = const Duration(minutes: 5),
    Key? key,
  }) : super(key: key);

  @override
  State<QueryBowlScope> createState() => _QueryBowlScopeState();
}

class _QueryBowlScopeState extends State<QueryBowlScope> {
  late Set<Query> queries;

  late Timer refreshIntervalTimer;

  @override
  void initState() {
    super.initState();
    queries = {};
    refreshIntervalTimer = Timer.periodic(
      widget.refreshInterval,
      _checkAndUpdateStaleQueriesOnBg,
    );
  }

  @override
  void dispose() {
    refreshIntervalTimer.cancel();
    _disposeListeners();
    super.dispose();
  }

  Future<void> _checkAndUpdateStaleQueriesOnBg([dynamic _]) async {
    // checking for staled queries inside the widget as InheritedWidget
    // classes has to be constant & doesn't this kind of dynamic behavior
    for (final query in queries) {
      if (query.isStale) await query.refetch();
    }
  }

  void _listenToQueryUpdate() {
    for (final query in queries) {
      query.addListener(() => updateQueries(query));
    }
  }

  void _disposeListeners() {
    for (final query in queries) {
      query.removeListener(() => updateQueries(query));
    }
  }

  void updateQueries(Query query) {
    setState(() {
      // checking & not including inactive queries
      // basically garbage collecting queries
      queries = Set.from(
        query.isInactive
            ? queries.where((el) => el.queryKey != query.queryKey)
            : queries,
      );
    });
  }

  void addQuery<T extends Object, Outside>(Query<T, Outside> query) {
    setState(() {
      queries = Set.from({...queries, query});
    });
  }

  @override
  Widget build(BuildContext context) {
    _disposeListeners();
    _listenToQueryUpdate();
    return QueryBowl(
      addQuery: addQuery,
      queries: queries,
      staleTime: widget.staleTime,
      child: widget.child,
    );
  }
}

/// QueryBowl holds all the query related methods & properties.
/// Its responsible for creating/updating/delete queries
class QueryBowl extends InheritedWidget {
  final Set<Query> _queries;
  final Duration staleTime;

  final void Function<T extends Object, Outside>(Query<T, Outside> query)
      _addQuery;

  const QueryBowl({
    required Widget child,
    required final void Function<T extends Object, Outside>(
            Query<T, Outside> query)
        addQuery,
    required final Set<Query> queries,
    required this.staleTime,
    Key? key,
  })  : _addQuery = addQuery,
        _queries = queries,
        super(child: child, key: key);

  Future<T?> fetchQuery<T extends Object, Outside>(
    QueryJob<T, Outside> options, {
    required Outside externalData,
    final QueryListener<T>? onData,
    final QueryListener<dynamic>? onError,
    Widget? mount,
  }) async {
    final prevQuery =
        _queries.firstWhereOrNull((q) => q.queryKey == options.queryKey);
    if (prevQuery is Query<T, Outside>) {
      // run the query if its still not called or if externalData has
      // changed
      final hasExternalDataChanged =
          prevQuery.prevUsedExternalData != externalData;
      if (mount != null) prevQuery.mount(mount);
      if (!prevQuery.hasData || hasExternalDataChanged) {
        if (hasExternalDataChanged) prevQuery.setExternalData(externalData);
        return prevQuery.fetched
            ? await prevQuery.refetch()
            : await prevQuery.fetch();
      }
      // mounting the widget that is using the query in the prevQuery
      return prevQuery.data;
    }
    final query = Query<T, Outside>.fromOptions(
      options,
      externalData: externalData,
      onData: onData,
      onError: onError,
    );
    if (mount != null) query.mount(mount);
    _addQuery<T, Outside>(query);
    return await query.fetch();
  }

  Query<T, Outside>? getQuery<T extends Object, Outside>(String queryKey) {
    return _queries.firstWhereOrNull((query) {
      return query.queryKey == queryKey && query is Query<T, Outside>;
    })?.cast<Query<T, Outside>>();
  }

  int get isFetching {
    return _queries.fold<int>(
      0,
      (acc, query) {
        if (query.isLoading || query.isRefetching) acc++;
        return acc;
      },
    );
  }

  void resetQuery(String queryKey) {
    _queries
        .firstWhereOrNull((element) => element.queryKey == queryKey)
        ?.reset();
  }

  static QueryBowl of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<QueryBowl>()!;

  @override
  bool updateShouldNotify(QueryBowl oldWidget) {
    return oldWidget.staleTime != staleTime || oldWidget._queries != _queries;
  }
}
