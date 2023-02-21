import 'dart:async';

import 'package:collection/collection.dart';
import 'package:fl_query/src/collections/default_configs.dart';
import 'package:fl_query/src/core/infinite_query.dart';
import 'package:fl_query/src/core/query.dart';

enum QueryCacheEventType {
  addQuery,
  addInfiniteQuery,
  removeQuery,
  removeInfiniteQuery,
}

class QueryCacheEvent {
  final QueryCacheEventType type;
  final Object data;

  QueryCacheEvent(this.type, this.data);
}

class QueryCache {
  final Set<Query> _queries;
  final Set<InfiniteQuery> _infiniteQueries;

  final Duration cacheDuration;

  final _eventController = StreamController<QueryCacheEvent>.broadcast();

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

  Stream<QueryCacheEvent> get events => _eventController.stream;

  void addQuery(Query query) {
    _queries.add(query);
    _eventController.add(
      QueryCacheEvent(QueryCacheEventType.addQuery, query),
    );
  }

  void addInfiniteQuery(InfiniteQuery query) {
    _infiniteQueries.add(query);
    _eventController.add(
      QueryCacheEvent(QueryCacheEventType.addInfiniteQuery, query),
    );
  }

  void removeQuery(Query query) {
    _queries.remove(query);
    _eventController.add(
      QueryCacheEvent(QueryCacheEventType.removeQuery, query),
    );
  }

  void removeInfiniteQuery(InfiniteQuery query) {
    _infiniteQueries.remove(query);
    _eventController.add(
      QueryCacheEvent(QueryCacheEventType.removeInfiniteQuery, query),
    );
  }
}
