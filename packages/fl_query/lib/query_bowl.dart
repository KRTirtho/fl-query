import 'dart:async';

import 'package:fl_query/query.dart';
import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';

class QueryBowlScope extends StatefulWidget {
  final Widget child;
  final Duration staleTime;

  /// used for periodically checking if any query got stale.
  /// If none is supplied then half of the value of staleTime is used
  final Duration? refreshInterval;
  const QueryBowlScope({
    required this.child,
    this.staleTime = const Duration(minutes: 5),
    this.refreshInterval,
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
      widget.refreshInterval ??
          Duration(
            milliseconds: (widget.staleTime.inMilliseconds / 2).round(),
          ),
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
      query.addListener(updateQueries);
    }
  }

  void _disposeListeners() {
    for (final query in queries) {
      query.removeListener(updateQueries);
    }
  }

  void updateQueries() {
    setState(() {
      queries = Set.from(queries);
    });
  }

  void addQuery(Query query) {
    setState(() {
      queries = Set.from({...queries, query});
    });
  }

  @override
  Widget build(BuildContext context) {
    _listenToQueryUpdate();
    return QueryBowl(
      onUpdate: updateQueries,
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

  final void Function(Query query) _addQuery;

  const QueryBowl({
    required Widget child,
    required final void Function() onUpdate,
    required final void Function(Query query) addQuery,
    required final Set<Query> queries,
    required this.staleTime,
    Key? key,
  })  : _addQuery = addQuery,
        _queries = queries,
        super(child: child, key: key);

  Future<T?> fetchQuery<T>(Query<T> query) async {
    final prevQuery =
        _queries.firstWhereOrNull((q) => q.queryKey == query.queryKey);
    if (prevQuery is Query<T>) {
      if (!prevQuery.hasData) {
        return prevQuery.fetched
            ? await prevQuery.refetch()
            : await prevQuery.fetch();
      }
      return prevQuery.data;
    }
    _addQuery(query);
    return await query.fetch();
  }

  Query<T>? getQuery<T>(String queryKey) {
    return _queries.firstWhereOrNull(
            (query) => query.queryKey == queryKey && query is Query<T>)
        as Query<T>?;
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
