import 'dart:async';

import 'package:collection/collection.dart';
import 'package:fl_query/src/collections/default_configs.dart';
import 'package:fl_query/src/core/infinite_query.dart';
import 'package:fl_query/src/core/query.dart';

class QueryCache {
  final Set<Query> _queries;
  final Set<InfiniteQuery> _infiniteQueries;

  final Duration cacheDuration;

  QueryCache({
    this.cacheDuration = DefaultConstants.cacheDuration,
  })  : _queries = Set<Query>(),
        _infiniteQueries = Set<InfiniteQuery>() {
    Timer.periodic(cacheDuration, (timer) {
      _queries.removeWhere((query) => query.isInactive);
      _infiniteQueries.removeWhere((query) => query.isInactive);
    });
  }

  UnmodifiableSetView<Query> get queries => UnmodifiableSetView(_queries);
  UnmodifiableSetView<InfiniteQuery> get infiniteQueries =>
      UnmodifiableSetView(_infiniteQueries);

  void addQuery(Query query) {
    _queries.add(query);
  }

  void addInfiniteQuery(InfiniteQuery query) {
    _infiniteQueries.add(query);
  }

  void removeQuery(Query query) {
    _queries.remove(query);
  }

  void removeInfiniteQuery(InfiniteQuery query) {
    _infiniteQueries.remove(query);
  }
}
