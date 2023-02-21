import 'package:collection/collection.dart';
import 'package:fl_query/src/collections/default_configs.dart';
import 'package:fl_query/src/collections/json_config.dart';
import 'package:fl_query/src/collections/refresh_config.dart';
import 'package:fl_query/src/collections/retry_config.dart';
import 'package:fl_query/src/core/cache.dart';
import 'package:fl_query/src/core/infinite_query.dart';
import 'package:fl_query/src/core/provider.dart';
import 'package:fl_query/src/core/query.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';

class QueryClient {
  final QueryCache cache;

  QueryClient({QueryCache? cache}) : this.cache = cache ?? QueryCache();

  Query<DataType, ErrorType, KeyType> createQuery<DataType, ErrorType, KeyType>(
    ValueKey<KeyType> key,
    QueryFn<DataType> queryFn, {
    DataType? initial,
    RetryConfig retryConfig = DefaultConstants.retryConfig,
    RefreshConfig refreshConfig = DefaultConstants.refreshConfig,
    JsonConfig<DataType>? jsonConfig,
  }) {
    final query = cache.queries
        .firstWhere(
          (query) => query.key == key,
          orElse: () => Query<DataType, ErrorType, KeyType>(
            key,
            queryFn,
            initial: initial,
            retryConfig: retryConfig,
            refreshConfig: refreshConfig,
            jsonConfig: jsonConfig,
          ),
        )
        .cast<DataType, ErrorType, KeyType>();
    query.updateQueryFn(queryFn);
    cache.addQuery(query);
    return query;
  }

  Future<DataType?> fetchQuery<DataType, ErrorType, KeyType>(
    ValueKey<KeyType> key,
    QueryFn<DataType> queryFn, {
    DataType? initial,
    RetryConfig retryConfig = DefaultConstants.retryConfig,
    RefreshConfig refreshConfig = DefaultConstants.refreshConfig,
    JsonConfig<DataType>? jsonConfig,
  }) async {
    final query = createQuery<DataType, ErrorType, KeyType>(
      key,
      queryFn,
      initial: initial,
      retryConfig: retryConfig,
      refreshConfig: refreshConfig,
      jsonConfig: jsonConfig,
    );
    return await query.fetch();
  }

  Query<DataType, ErrorType, KeyType>? getQuery<DataType, ErrorType, KeyType>(
      ValueKey<KeyType> key) {
    return cache.queries
        .firstWhereOrNull((query) => query.key == key)
        ?.cast<DataType, ErrorType, KeyType>();
  }

  List<Query> getQueries(List<ValueKey> keys) {
    return cache.queries.where((query) => keys.contains(query.key)).toList();
  }

  Future<DataType?> refreshQuery<DataType, ErrorType, KeyType>(
      ValueKey<KeyType> key,
      {DataType? initial}) async {
    final query = getQuery<DataType, ErrorType, KeyType>(key);
    if (query == null) return null;
    return await query.refresh();
  }

  Future<List> refreshQueries(List<ValueKey> keys) async {
    final queries = getQueries(keys);
    return await Future.wait(queries.map((query) => query.refresh()));
  }

  InfiniteQuery<DataType, ErrorType, KeyType, PageType>
      createInfiniteQuery<DataType, ErrorType, KeyType, PageType>(
    ValueKey<KeyType> key,
    InfiniteQueryFn<DataType, PageType> queryFn, {
    required InfiniteQueryNextPage<DataType, PageType> nextPage,
    required PageType initialParam,
    RetryConfig retryConfig = DefaultConstants.retryConfig,
    RefreshConfig refreshConfig = DefaultConstants.refreshConfig,
    JsonConfig<DataType>? jsonConfig,
  }) {
    final query = cache.infiniteQueries
        .firstWhere(
          (query) => query.key == key,
          orElse: () => InfiniteQuery<DataType, ErrorType, KeyType, PageType>(
            key,
            queryFn,
            nextPage: nextPage,
            initialParam: initialParam,
            retryConfig: retryConfig,
            refreshConfig: refreshConfig,
            jsonConfig: jsonConfig,
          ),
        )
        .cast<DataType, ErrorType, KeyType, PageType>();
    query.updateQueryFn(queryFn);
    cache.addInfiniteQuery(query);
    return query;
  }

  Future<DataType?> fetchInfiniteQuery<DataType, ErrorType, KeyType, PageType>(
      ValueKey<KeyType> key, InfiniteQueryFn<DataType, PageType> queryFn,
      {required InfiniteQueryNextPage<DataType, PageType> nextPage,
      required PageType initialParam,
      RetryConfig retryConfig = DefaultConstants.retryConfig,
      RefreshConfig refreshConfig = DefaultConstants.refreshConfig,
      JsonConfig<DataType>? jsonConfig}) async {
    final query = createInfiniteQuery<DataType, ErrorType, KeyType, PageType>(
      key,
      queryFn,
      nextPage: nextPage,
      initialParam: initialParam,
      retryConfig: retryConfig,
      refreshConfig: refreshConfig,
      jsonConfig: jsonConfig,
    );
    return await query.fetch();
  }

  InfiniteQuery<DataType, ErrorType, KeyType, PageType>?
      getInfiniteQuery<DataType, ErrorType, KeyType, PageType>(
          ValueKey<KeyType> key) {
    return cache.infiniteQueries
        .firstWhereOrNull((query) => query.key == key)
        ?.cast<DataType, ErrorType, KeyType, PageType>();
  }

  List<InfiniteQuery> getInfiniteQueries(List<ValueKey> keys) {
    return cache.infiniteQueries
        .where((query) => keys.contains(query.key))
        .toList();
  }

  Future<DataType?>
      refreshInfiniteQuery<DataType, ErrorType, KeyType, PageType>(
          ValueKey<KeyType> key,
          [PageType? page]) async {
    final query = getInfiniteQuery<DataType, ErrorType, KeyType, PageType>(key);
    if (query == null) return null;
    return await query.refresh(page);
  }

  Future<List<DataType>?>
      refreshInfiniteQueryAllPages<DataType, ErrorType, KeyType, PageType>(
          ValueKey<KeyType> key) async {
    final query = getInfiniteQuery<DataType, ErrorType, KeyType, PageType>(key);
    if (query == null) return [];
    return await query.refreshAll();
  }

  Future<List> refreshInfiniteQueries(List<ValueKey> keys) async {
    final queries = getInfiniteQueries(keys);
    return await Future.wait(queries.map((query) => query.refresh()));
  }

  Future<Map<ValueKey, List?>> refreshInfiniteQueriesAllPages(
      List<ValueKey> keys) async {
    final queries = getInfiniteQueries(keys);
    return await Future.wait(queries.map(
            (query) async => MapEntry(query.key, await query.refreshAll())))
        .then((qs) => Map.fromEntries(qs));
  }

  static QueryClient of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<QueryClientProvider>()!
        .client;
  }

  static QueryClient? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<QueryClientProvider>()
        ?.client;
  }

  static Future<void> initialize({String? cacheDir}) async {
    await Hive.initFlutter(cacheDir);
    await Hive.openLazyBox('cache');
  }
}
