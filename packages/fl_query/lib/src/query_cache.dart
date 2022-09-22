import 'package:collection/collection.dart';
import 'package:fl_query/fl_query.dart';
import 'package:fl_query/src/base_operation.dart';

typedef ReadonlySet<E> = UnmodifiableSetView<E>;

enum CacheEvent {
  clearCache,
  query,
  infiniteQuery,
  mutation,
}

typedef CacheUpdateListener<T> = void Function(CacheEvent event, T? changes);

class QueryCache {
  /// Removes inactive queries after provided duration of [cacheTime]
  final Duration cacheTime;

  QueryCache({Duration? cacheTime})
      : cacheTime = cacheTime ?? const Duration(minutes: 5) {}

  final Set<Query> _queries = {};
  final Set<InfiniteQuery> _infiniteQueries = {};
  final Set<Mutation> _mutations = {};

  final Set<CacheUpdateListener<BaseOperation>> _listeners = {};

  ReadonlySet<Query> get queries => UnmodifiableSetView(_queries);
  ReadonlySet<InfiniteQuery> get infiniteQueries =>
      UnmodifiableSetView(_infiniteQueries);
  ReadonlySet<Mutation> get mutations => UnmodifiableSetView(_mutations);

  ReadonlySet<CacheUpdateListener<BaseOperation>> get listeners =>
      UnmodifiableSetView(_listeners);

  _notifyListeners<T extends Object>(CacheEvent event, changes) {
    _listeners.forEach((listener) => listener(event, changes));
  }

  _listenToQueryChanges(Query query) {
    query.addListener(() {
      if (query.isInactive) {
        _queries.removeWhere((el) => el.queryKey != query.queryKey);
        _notifyListeners(CacheEvent.query, null);
      } else {
        _notifyListeners(CacheEvent.query, query);
      }
    });
  }

  _listenToInfiniteQueryChanges(InfiniteQuery infiniteQuery) {
    infiniteQuery.addListener(() {
      if (infiniteQuery.isInactive) {
        _infiniteQueries
            .removeWhere((el) => el.queryKey != infiniteQuery.queryKey);
        _notifyListeners(CacheEvent.infiniteQuery, null);
      } else {
        _notifyListeners(CacheEvent.infiniteQuery, infiniteQuery);
      }
    });
  }

  _listenToMutationChanges(Mutation mutation) {
    mutation.addListener(() {
      if (mutation.isInactive) {
        _mutations.removeWhere(
          (el) => el.mutationKey != mutation.mutationKey,
        );
        _notifyListeners(CacheEvent.mutation, null);
      } else {
        _notifyListeners(CacheEvent.mutation, mutation);
      }
    });
  }

  void addQuery(Query query) {
    _queries.add(query);
    _listenToQueryChanges(query);
    _notifyListeners(CacheEvent.query, query);
  }

  void addInfiniteQuery(InfiniteQuery infiniteQuery) {
    _infiniteQueries.add(infiniteQuery);
    _listenToInfiniteQueryChanges(infiniteQuery);
    _notifyListeners(CacheEvent.infiniteQuery, infiniteQuery);
  }

  void addMutation(Mutation mutation) {
    _mutations.add(mutation);
    _listenToMutationChanges(mutation);
    _notifyListeners(CacheEvent.mutation, mutation);
  }

  void removeQuery(Query query) {
    _queries.remove(query);
    _notifyListeners(CacheEvent.query, null);
  }

  void removeInfiniteQuery(InfiniteQuery infiniteQuery) {
    _infiniteQueries.remove(infiniteQuery);
    _notifyListeners(CacheEvent.infiniteQuery, null);
  }

  void removeMutation(Mutation mutation) {
    _mutations.remove(mutation);
    _notifyListeners(CacheEvent.mutation, null);
  }

  void clearCache() {
    _infiniteQueries.clear();
    _queries.clear();
    _mutations.clear();
    _notifyListeners(CacheEvent.clearCache, null);
  }

  void on(CacheUpdateListener<BaseOperation?> listener) {
    _listeners.add(listener);
  }

  void off(CacheUpdateListener<BaseOperation?> listener) {
    _listeners.remove(listener);
  }
}
