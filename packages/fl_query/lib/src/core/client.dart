import 'dart:async';

import 'package:collection/collection.dart';
import 'package:fl_query/src/collections/connectivity_adapter.dart';
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

/// Base Client for managing [Query], [InfiniteQuery] and [Mutation] objects
/// and all related configuration
///
/// [QueryClient] is the basic imperative API to handle and manage Queries and
/// Mutations and used internally by the Declarative wrapper widgets and hooks
///
/// Usually, it can be helpful to use when only data modification is needed
/// without any UI changes e.g. after completing an action
///
/// It can be accessed anywhere in the widget tree using [QueryClient.of] or
/// [QueryClient.maybeOf]
///
/// ```dart
/// final queryClient = QueryClient.of(context);
///
/// await queryClient.refreshQuery('todos');
/// ```
///
/// If you don't have access to [BuildContext] e.g. in a [Provider] or [BLoC]
/// you can initialize your own [QueryClient] globally and pass it [QueryClientProvider]
/// and use it anywhere in the widget tree
///
/// ```dart
/// final queryClient = QueryClient();
///
/// QueryClientProvider(
///  client: queryClient,
///  child: (....)
/// )
///
/// // Somewhere else in the project
/// import 'package:example/config/query_client.dart';
///
/// class TodoListNotifier extends ChangeNotifier {
///   void addTodo(Todo todo) async {
///     final res = post(api, todo);
///
///     await queryClient.refreshQuery('todos');
///   }
/// }
/// ```
///
/// * The above can be also implemented using just by [Mutation]

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

  /// Imperatively creates a [Query]
  ///
  /// If a query with the same key already exists, it will be returned
  /// and the properties will be updated (if changed)
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

  /// Creates + stores a [Query] and runs the [queryFn] immediately
  /// and returns the result
  ///
  /// - If fails, returns with `null`
  /// - If [Query] already exists, it'll run the [Query.fetch] anyway
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

  /// Finds the [Query] with the given [key] and returns it
  ///
  /// [exact] can be used to match the key exactly or by prefix
  Query<DataType, ErrorType>? getQuery<DataType, ErrorType>(
    String key, {
    bool exact = true,
  }) {
    return cache.queries
        .firstWhereOrNull(
          (query) => exact ? query.key == key : query.key.startsWith(key),
        )
        ?.cast<DataType, ErrorType>();
  }

  List<Query> getQueries(List<String> keys) {
    return cache.queries.where((query) => keys.contains(query.key)).toList();
  }

  /// Finds all the [Query] that starts with the given [prefix]
  List<Query> getQueriesWithPrefix(String prefix) {
    return cache.queries
        .where((query) => query.key.startsWith(prefix))
        .toList();
  }

  /// Finds the [Query] with the given [key] and refreshes using [Query.refresh]
  ///
  /// [exact] can be used to match the key exactly or by prefix
  Future<DataType?> refreshQuery<DataType, ErrorType>(
    String key, {
    bool exact = true,
  }) async {
    final query = getQuery<DataType, ErrorType>(key, exact: exact);
    if (query == null) return null;
    return await query.refresh();
  }

  Future<List> refreshQueries(List<String> keys) async {
    final queries = getQueries(keys);
    return await Future.wait(queries.map((query) => query.refresh()));
  }

  /// Finds all the [Query] that starts with the given [prefix]
  /// and refreshes
  Future<List> refreshQueriesWithPrefix(String prefix) async {
    final queries = getQueriesWithPrefix(prefix);
    return await Future.wait(queries.map((query) => query.refresh()));
  }

  /// Creates + stores an [InfiniteQuery]
  ///
  /// If [InfinityQuery] already exists, it'll return the existing one
  /// and update the configuration if changed
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

  /// Creates + stores an [InfiniteQuery] and fetches the first page
  /// immediately and returns the result
  ///
  /// - If fails, returns with `null`
  /// - If [InfiniteQuery] already exists, it'll run the [InfiniteQuery.fetch] anyway
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

  /// Finds the [InfiniteQuery] with the given [key]
  ///
  /// [exact] can be used to match the key exactly or by prefix
  InfiniteQuery<DataType, ErrorType, PageType>?
      getInfiniteQuery<DataType, ErrorType, PageType>(
    String key, {
    bool exact = true,
  }) {
    return cache.infiniteQueries
        .firstWhereOrNull(
            (query) => exact ? query.key == key : query.key.startsWith(key))
        ?.cast<DataType, ErrorType, PageType>();
  }

  List<InfiniteQuery> getInfiniteQueries(List<String> keys) {
    return cache.infiniteQueries
        .where((query) => keys.contains(query.key))
        .toList();
  }

  /// Finds all the [InfiniteQuery] that starts with the given [prefix]
  List<InfiniteQuery> getInfiniteQueriesWithPrefix(String prefix) {
    return cache.infiniteQueries
        .where((query) => query.key.startsWith(prefix))
        .toList();
  }

  /// Finds the [InfiniteQuery] with the given [key] and refreshes
  /// using [InfiniteQuery.refresh]
  ///
  /// It'll return the refreshed data and will return `null` if fails
  ///
  /// - [exact] can be used to match the key exactly or by prefix
  /// - [page] can be used to only refresh a specific page or else it'll
  ///   refresh the lastPage
  ///
  Future<DataType?> refreshInfiniteQuery<DataType, ErrorType, PageType>(
    String key, {
    PageType? page,
    bool exact = true,
  }) async {
    final query =
        getInfiniteQuery<DataType, ErrorType, PageType>(key, exact: exact);
    if (query == null) return null;
    return await query.refresh(page);
  }

  /// Finds the [InfiniteQuery] with the given [key] and refreshes all pages
  /// using [InfiniteQuery.refreshAll]
  ///
  /// It'll return the refreshed data and will return `null` if fails
  ///
  /// - [exact] can be used to match the key exactly or by prefix
  Future<List<DataType>?>
      refreshInfiniteQueryAllPages<DataType, ErrorType, PageType>(
    String key, {
    bool exact = true,
  }) async {
    final query =
        getInfiniteQuery<DataType, ErrorType, PageType>(key, exact: exact);
    if (query == null) return [];
    return await query.refreshAll();
  }

  Future<List> refreshInfiniteQueries(List<String> keys) async {
    final queries = getInfiniteQueries(keys);
    return await Future.wait(queries.map((query) => query.refresh()));
  }

  /// Finds all the [InfiniteQuery] that starts with the given [prefix]
  /// and refreshes using [InfiniteQuery.refresh]
  ///
  /// It'll return the refreshed data and will return `null` if fails
  Future<List> refreshInfiniteQueriesWithPrefix(String prefix) async {
    final queries = getInfiniteQueriesWithPrefix(prefix);
    return await Future.wait(queries.map((query) => query.refresh()));
  }

  Future<Map<String, List?>> refreshInfiniteQueriesAllPages(
    List<String> keys,
  ) async {
    final queries = getInfiniteQueries(keys);
    return await Future.wait(queries.map(
            (query) async => MapEntry(query.key, await query.refreshAll())))
        .then((qs) => Map.fromEntries(qs));
  }

  /// Finds all the [InfiniteQuery] that starts with the given [prefix]
  /// and refreshes all pages using [InfiniteQuery.refreshAll]
  ///
  /// It returns a Map with the key as the matched query key and the value
  /// as the refreshed data
  ///
  /// It'll return the refreshed data and will return `null` if fails
  Future<Map<String, List?>> refreshInfiniteQueriesAllPagesWithPrefix(
    String prefix,
  ) async {
    final queries = getInfiniteQueriesWithPrefix(prefix);
    return await Future.wait(queries.map(
            (query) async => MapEntry(query.key, await query.refreshAll())))
        .then((qs) => Map.fromEntries(qs));
  }

  /// Creates a new [Mutation]
  ///
  /// If a [Mutation] with the same [key] already exists, it'll return the
  /// existing [Mutation] and update the properties of the existing [Mutation]
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

  /// Finds the [Mutation] with the given [key] and runs [Mutation.mutate]
  ///
  /// It'll return the mutation result and will return `null` if fails
  ///
  /// Optionally takes an [mutationFn] to override the existing [mutationFn]
  /// or create a completely new [Mutation] if doesn't exist
  /// Same situation for [retryConfig]
  ///
  /// - [refreshQueries] can be used to refresh queries after mutation
  /// - [refreshInfiniteQueries] can be used to refresh infinite queries
  ///   after mutation
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

  /// Finds the [Mutation]
  ///
  /// - [exact] can be used to match the key exactly or by prefix
  Mutation<DataType, ErrorType, VariablesType>?
      getMutation<DataType, ErrorType, VariablesType>(
    String key, {
    bool exact = true,
  }) {
    return cache.mutations
        .firstWhereOrNull(
            (query) => exact ? query.key == key : query.key.startsWith(key))
        ?.cast<DataType, ErrorType, VariablesType>();
  }

  /// Gets the [QueryClient] from the [BuildContext] if available
  ///
  /// This can throw an error if the [QueryClient] is not available
  static QueryClient of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<QueryClientProvider>()!
        .client;
  }

  /// Gets the [QueryClient] from the [BuildContext] if available
  static QueryClient? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<QueryClientProvider>()
        ?.client;
  }

  static String _cachePrefix = 'fl_query';

  static String get queryCachePrefix => '$_cachePrefix.cache.queries';
  static String get infiniteQueryCachePrefix =>
      '$_cachePrefix.cache.infinite_queries';

  static late final ConnectivityAdapter connectivity;

  /// Initializes the [QueryClient]
  ///
  /// This sets up all [Hive] boxes and cache directories
  static Future<void> initialize({
    required String cachePrefix,
    required ConnectivityAdapter connectivity,
    String? cacheDir,
  }) async {
    connectivity = connectivity;
    await Hive.initFlutter(cacheDir);
    _cachePrefix = cachePrefix;
    await Hive.openLazyBox(queryCachePrefix);
    await Hive.openLazyBox(infiniteQueryCachePrefix);
  }
}
