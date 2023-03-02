import 'dart:async';

import 'package:collection/collection.dart';
import 'package:fl_query/src/collections/default_configs.dart';
import 'package:fl_query/src/collections/json_config.dart';
import 'package:fl_query/src/collections/refresh_config.dart';
import 'package:fl_query/src/collections/retry_config.dart';
import 'package:fl_query/src/core/cache.dart';
import 'package:fl_query/src/core/infinite_query.dart';
import 'package:fl_query/src/core/mutation.dart';
import 'package:fl_query/src/core/provider.dart';
import 'package:fl_query/src/core/query.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';

@immutable
class QueryClient {
  final QueryCache cache;

  final RetryConfig retryConfig;
  final RefreshConfig refreshConfig;
  final Duration cacheDuration;

  QueryClient({
    QueryCache? cache,
    this.cacheDuration = DefaultConstants.cacheDuration,
    int? maxRetries,
    Duration? retryDelay,
    Duration? staleDuration,
    Duration? refreshInterval,
    bool? refreshOnMount,
    bool? refreshOnQueryFnChange,
  })  : this.cache = cache ?? QueryCache(cacheDuration: cacheDuration),
        this.retryConfig = DefaultConstants.retryConfig.copyWith(
          maxRetries: maxRetries,
          retryDelay: retryDelay,
        ),
        this.refreshConfig = DefaultConstants.refreshConfig.copyWith(
          staleDuration: staleDuration,
          refreshInterval: refreshInterval,
          refreshOnMount: refreshOnMount,
          refreshOnQueryFnChange: refreshOnQueryFnChange,
        );

  Query<DataType, ErrorType> createQuery<DataType, ErrorType>(
    String key,
    QueryFn<DataType> queryFn, {
    DataType? initial,
    RetryConfig? retryConfig,
    RefreshConfig? refreshConfig,
    JsonConfig<DataType>? jsonConfig,
  }) {
    final query = cache.queries
        .firstWhere(
          (query) => query.key == key,
          orElse: () => Query<DataType, ErrorType>(
            key,
            queryFn,
            initial: initial,
            retryConfig: retryConfig ?? this.retryConfig,
            refreshConfig: refreshConfig ?? this.refreshConfig,
            jsonConfig: jsonConfig,
          ),
        )
        .cast<DataType, ErrorType>();
    query.updateQueryFn(queryFn);
    cache.addQuery(query);
    return query;
  }

  Future<DataType?> fetchQuery<DataType, ErrorType>(
    String key,
    QueryFn<DataType> queryFn, {
    DataType? initial,
    RetryConfig? retryConfig,
    RefreshConfig? refreshConfig,
    JsonConfig<DataType>? jsonConfig,
  }) async {
    try {
      DataType? result;
      final completer = Completer<DataType>();
      final query = createQuery<DataType, ErrorType>(
        key,
        queryFn,
        initial: initial,
        retryConfig: retryConfig,
        refreshConfig: refreshConfig,
        jsonConfig: jsonConfig,
      );

      final subscription = query.dataStream.listen((data) {
        if (!completer.isCompleted) completer.complete(data);
      });

      final errorSubscription = query.errorStream.listen((error) {
        if (!completer.isCompleted)
          completer.completeError(error != null ? error : "");
      });

      result = await query.fetch();
      result ??= await completer.future;

      errorSubscription.cancel();
      subscription.cancel();
      return result;
    } catch (e) {
      return null;
    }
  }

  Query<DataType, ErrorType>? getQuery<DataType, ErrorType>(
    String key,
  ) {
    return cache.queries
        .firstWhereOrNull((query) => query.key == key)
        ?.cast<DataType, ErrorType>();
  }

  List<Query> getQueries(List<String> keys) {
    return cache.queries.where((query) => keys.contains(query.key)).toList();
  }

  Future<DataType?> refreshQuery<DataType, ErrorType>(String key,
      {DataType? initial}) async {
    final query = getQuery<DataType, ErrorType>(key);
    if (query == null) return null;
    return await query.refresh();
  }

  Future<List> refreshQueries(List<String> keys) async {
    final queries = getQueries(keys);
    return await Future.wait(queries.map((query) => query.refresh()));
  }

  InfiniteQuery<DataType, ErrorType, PageType>
      createInfiniteQuery<DataType, ErrorType, PageType>(
    String key,
    InfiniteQueryFn<DataType, PageType> queryFn, {
    required InfiniteQueryNextPage<DataType, PageType> nextPage,
    required PageType initialParam,
    RetryConfig? retryConfig,
    RefreshConfig? refreshConfig,
    JsonConfig<DataType>? jsonConfig,
  }) {
    final query = cache.infiniteQueries
        .firstWhere(
          (query) => query.key == key,
          orElse: () => InfiniteQuery<DataType, ErrorType, PageType>(
            key,
            queryFn,
            nextPage: nextPage,
            initialParam: initialParam,
            retryConfig: retryConfig ?? this.retryConfig,
            refreshConfig: refreshConfig ?? this.refreshConfig,
            jsonConfig: jsonConfig,
          ),
        )
        .cast<DataType, ErrorType, PageType>();
    query.updateQueryFn(queryFn);
    query.updateNextPageFn(nextPage);
    cache.addInfiniteQuery(query);
    return query;
  }

  Future<DataType?> fetchInfiniteQuery<DataType, ErrorType, PageType>(
    String key,
    InfiniteQueryFn<DataType, PageType> queryFn, {
    required InfiniteQueryNextPage<DataType, PageType> nextPage,
    required PageType initialParam,
    RetryConfig? retryConfig,
    RefreshConfig? refreshConfig,
    JsonConfig<DataType>? jsonConfig,
  }) async {
    try {
      DataType? result;
      final completer = Completer<DataType>();
      final query = createInfiniteQuery<DataType, ErrorType, PageType>(
        key,
        queryFn,
        nextPage: nextPage,
        initialParam: initialParam,
        retryConfig: retryConfig,
        refreshConfig: refreshConfig,
        jsonConfig: jsonConfig,
      );

      final subscription = query.dataStream.listen((event) {
        if (!completer.isCompleted) completer.complete(event.data);
      });

      final errorSubscription = query.errorStream.listen((event) {
        if (!completer.isCompleted)
          completer.completeError(event.data != null ? event.data! : "");
      });

      result = await query.fetch();
      result ??= await completer.future;

      errorSubscription.cancel();
      subscription.cancel();
      return result;
    } catch (e) {
      return null;
    }
  }

  InfiniteQuery<DataType, ErrorType, PageType>?
      getInfiniteQuery<DataType, ErrorType, PageType>(String key) {
    return cache.infiniteQueries
        .firstWhereOrNull((query) => query.key == key)
        ?.cast<DataType, ErrorType, PageType>();
  }

  List<InfiniteQuery> getInfiniteQueries(List<String> keys) {
    return cache.infiniteQueries
        .where((query) => keys.contains(query.key))
        .toList();
  }

  Future<DataType?> refreshInfiniteQuery<DataType, ErrorType, PageType>(
      String key,
      [PageType? page]) async {
    final query = getInfiniteQuery<DataType, ErrorType, PageType>(key);
    if (query == null) return null;
    return await query.refresh(page);
  }

  Future<List<DataType>?>
      refreshInfiniteQueryAllPages<DataType, ErrorType, PageType>(
          String key) async {
    final query = getInfiniteQuery<DataType, ErrorType, PageType>(key);
    if (query == null) return [];
    return await query.refreshAll();
  }

  Future<List> refreshInfiniteQueries(List<String> keys) async {
    final queries = getInfiniteQueries(keys);
    return await Future.wait(queries.map((query) => query.refresh()));
  }

  Future<Map<String, List?>> refreshInfiniteQueriesAllPages(
      List<String> keys) async {
    final queries = getInfiniteQueries(keys);
    return await Future.wait(queries.map(
            (query) async => MapEntry(query.key, await query.refreshAll())))
        .then((qs) => Map.fromEntries(qs));
  }

  Mutation<DataType, ErrorType, VariablesType>
      createMutation<DataType, ErrorType, VariablesType>(
    String key,
    MutationFn<DataType, VariablesType> mutationFn, {
    RetryConfig? retryConfig,
  }) {
    final mutation = cache.mutations
        .firstWhere(
          (query) => query.key == key,
          orElse: () => Mutation<DataType, ErrorType, VariablesType>(
            key,
            mutationFn,
            retryConfig: retryConfig ?? this.retryConfig,
          ),
        )
        .cast<DataType, ErrorType, VariablesType>();

    mutation.updateMutationFn(mutationFn);
    cache.addMutation(mutation);
    return mutation;
  }

  Future<DataType?> mutateMutation<DataType, ErrorType, VariablesType>(
    String key,
    VariablesType variables, {
    MutationFn<DataType, VariablesType>? mutationFn,
    RetryConfig? retryConfig,
    List<String> refreshQueries = const [],
    List<String> refreshInfiniteQueries = const [],
  }) async {
    try {
      DataType? result;
      final completer = Completer<DataType>();
      final mutation = getMutation<DataType, ErrorType, VariablesType>(
            key,
          ) ??
          (mutationFn != null
              ? createMutation<DataType, ErrorType, VariablesType>(
                  key,
                  mutationFn,
                  retryConfig: retryConfig,
                )
              : null);

      final subscription = mutation?.dataStream.listen((data) {
        if (!completer.isCompleted) completer.complete(data);
      });

      final errorSubscription = mutation?.errorStream.listen((error) {
        if (!completer.isCompleted)
          completer.completeError(error != null ? error : "");
      });

      result = await mutation?.mutate(variables);
      result ??= await completer.future;

      errorSubscription?.cancel();
      subscription?.cancel();

      await this.refreshQueries(refreshQueries);
      await refreshInfiniteQueriesAllPages(refreshInfiniteQueries);
      return result;
    } catch (e) {
      return null;
    }
  }

  Mutation<DataType, ErrorType, VariablesType>?
      getMutation<DataType, ErrorType, VariablesType>(String key) {
    return cache.mutations
        .firstWhereOrNull((query) => query.key == key)
        ?.cast<DataType, ErrorType, VariablesType>();
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

  static String _cachePrefix = 'fl_query';

  static String get queryCachePrefix => '$_cachePrefix.cache.queries';
  static String get infiniteQueryCachePrefix =>
      '$_cachePrefix.cache.infinite_queries';

  static Future<void> initialize({
    required String cachePrefix,
    String? cacheDir,
  }) async {
    await Hive.initFlutter(cacheDir);
    _cachePrefix = cachePrefix;
    await Hive.openLazyBox(queryCachePrefix);
    await Hive.openLazyBox(infiniteQueryCachePrefix);
  }
}
