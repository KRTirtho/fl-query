import 'dart:async';

import 'package:collection/collection.dart';
import 'package:fl_query/src/collections/default_configs.dart';
import 'package:fl_query/src/core/client.dart';
import 'package:fl_query/src/core/infinite_query.dart';
import 'package:fl_query/src/core/mutation.dart';
import 'package:fl_query/src/core/query.dart';
import 'package:hive_flutter/hive_flutter.dart';

enum QueryCacheEventType {
  addQuery,
  addInfiniteQuery,
  addMutation,
  removeQuery,
  removeInfiniteQuery,
  removeMutation,
}

class QueryCacheEvent {
  final QueryCacheEventType type;
  final Object data;

  QueryCacheEvent(this.type, this.data);
}

class QueryCache {
  final Set<Query> _queries;
  final Set<InfiniteQuery> _infiniteQueries;
  final Set<Mutation> _mutations;

  final Duration cacheDuration;

  final _eventController = StreamController<QueryCacheEvent>.broadcast();

  QueryCache({
    this.cacheDuration = DefaultConstants.cacheDuration,
  })  : _queries = Set<Query>(),
        _infiniteQueries = Set<InfiniteQuery>(),
        _mutations = Set<Mutation>() {
    Timer.periodic(cacheDuration, (timer) {
      _queries.removeWhere((query) {
        if (query.isInactive) {
          _eventController.add(
            QueryCacheEvent(QueryCacheEventType.removeQuery, query),
          );
        }
        return query.isInactive;
      });
      _infiniteQueries.removeWhere((query) {
        if (query.isInactive) {
          _eventController.add(
            QueryCacheEvent(QueryCacheEventType.removeInfiniteQuery, query),
          );
        }
        return query.isInactive;
      });
      _mutations.removeWhere((mutation) {
        if (mutation.isInactive) {
          _eventController.add(
            QueryCacheEvent(QueryCacheEventType.removeMutation, mutation),
          );
        }
        return mutation.isInactive;
      });
    });
  }

  UnmodifiableSetView<Query> get queries => UnmodifiableSetView(_queries);
  UnmodifiableSetView<InfiniteQuery> get infiniteQueries =>
      UnmodifiableSetView(_infiniteQueries);
  UnmodifiableSetView<Mutation> get mutations =>
      UnmodifiableSetView(_mutations);

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

  void addMutation(Mutation mutation) {
    _mutations.add(mutation);
    _eventController.add(
      QueryCacheEvent(QueryCacheEventType.addMutation, mutation),
    );
  }

  void removeMutation(Mutation mutation) {
    _mutations.remove(mutation);
    _eventController.add(
      QueryCacheEvent(QueryCacheEventType.removeMutation, mutation),
    );
  }

  void clear() {
    _queries.clear();
    _infiniteQueries.clear();
    _mutations.clear();
  }

  LazyBox get queryHiveBox => Hive.lazyBox(QueryClient.queryCachePrefix);
  LazyBox get infiniteQueryHiveBox =>
      Hive.lazyBox(QueryClient.infiniteQueryCachePrefix);
}
