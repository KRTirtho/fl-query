import 'package:fl_query/query.dart';
import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';

class QueryBowlScope extends StatefulWidget {
  final Widget child;
  final Duration? staleTime;
  const QueryBowlScope({
    required this.child,
    this.staleTime,
    Key? key,
  }) : super(key: key);

  @override
  State<QueryBowlScope> createState() => _QueryBowlScopeState();
}

class _QueryBowlScopeState extends State<QueryBowlScope> {
  late Set<Query> queries;

  @override
  void initState() {
    super.initState();
    queries = {};
  }

  void updateQueries() {
    setState(() {
      queries = Set.from(queries);
    });
  }

  @override
  Widget build(BuildContext context) {
    return QueryBowl(
      onUpdate: updateQueries,
      queries: queries,
      child: widget.child,
    );
  }
}

class QueryBowl extends InheritedWidget {
  final Set<Query> queries;
  final Duration staleTime;
  final void Function() onUpdate;

  const QueryBowl({
    required Widget child,
    required this.onUpdate,
    required this.queries,
    this.staleTime = const Duration(minutes: 5),
    Key? key,
  }) : super(child: child, key: key);

  listenToQueryUpdate() {
    for (final query in queries) {
      query.addListener(onUpdate);
    }
  }

  void disposeListeners() {
    for (final query in queries) {
      query.removeListener(onUpdate);
    }
  }

  Future<T?> fetchQuery<T>(Query<T> query) async {
    final prevQuery =
        queries.firstWhereOrNull((q) => q.queryKey == query.queryKey);
    if (prevQuery is Query<T>) {
      if (!prevQuery.hasData) {
        return prevQuery.fetched
            ? await prevQuery.refetch()
            : await prevQuery.fetch();
      }
      return prevQuery.data;
    }
    queries.add(query);
    disposeListeners();
    listenToQueryUpdate();
    return await query.fetch();
  }

  Query<T>? getQuery<T>(String queryKey) {
    return queries.firstWhereOrNull(
            (query) => query.queryKey == queryKey && query is Query<T>)
        as Query<T>?;
  }

  static QueryBowl of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<QueryBowl>()!;

  @override
  bool updateShouldNotify(QueryBowl oldWidget) {
    return oldWidget.staleTime != staleTime || oldWidget.queries != queries;
  }
}
