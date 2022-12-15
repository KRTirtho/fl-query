import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fl_query/fl_query.dart';
import 'package:fl_query/src/query_cache.dart';
import 'package:fl_query/src/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// The widget that holds every [Query] & [Mutation] to your
/// entire Flutter application in anywhere
/// [QueryBowl] provides an imperative way to handle all the query &
/// mutation related methods & properties.
/// Its responsible or can be used for (not recommended) creating,
/// updating & deleting queries & mutations
///
/// This must be used along with [QueryBowlScope]
///
/// ```dart
///  Widget build(BuildContext context) {
///    return QueryBowlScope(
///      bowl: QueryBowl(),
///      child: MaterialApp(/*...other stuff...*/),
///    );
///  }
/// ```
///
class QueryBowl {
  /// global stale time
  ///
  /// Makes [Query.data] stale after crossing the duration of provided
  /// [staleTime]
  final Duration staleTime;

  // refetching options

  /// refetch query when new query instance mounts
  final bool refetchOnMount;

  /// refetch when desktop/web app regains Focus
  final bool refetchOnWindowFocus;

  /// the delay to call each query when desktop/web application gets focused after
  /// being unfocused. Using a delay after each refetch so refetching all the
  /// queries at once won't create high CPU spikes & also wouldn't violate
  /// rate-limit
  ///
  /// Though its recommended most of the time to use but it can be turned
  /// off by passing [Duration.zero]
  final Duration refetchOnWindowFocusDelay;

  /// refetch when application resumes from the background in mobile devices
  final bool refetchOnApplicationResume;

  /// the delay to call each query when app resumes from the background in
  /// mobile devices. Using a delay after each refetch so refetching all the
  /// queries at once won't create high CPU spikes & also wouldn't violate
  /// rate-limit
  ///
  /// Though its recommended most of the time to use but it can be turned
  /// off by passing [Duration.zero]
  final Duration refetchOnApplicationResumeDelay;

  /// refetch when user's device reconnects to the internet after not being
  /// connected before
  final bool refetchOnReconnect;

  /// the delay to call each query when user device reconnects to the
  /// internet. Using a delay after each refetch so refetching all the
  /// queries at once won't create high CPU spikes & also wouldn't violate
  /// rate-limit
  ///
  /// Though its recommended most of the time to use but it can be turned
  /// off by passing [Duration.zero]
  final Duration refetchOnReconnectDelay;

  /// Refetch the query whenever the data passed as [externalData] to any
  /// [QueryBuilder] or [useQuery] changes
  ///
  /// If set to false than the [externalData] will get updated but there
  /// won't be any query update
  final bool refetchOnExternalDataChange;

  /// used for periodically checking if any query got stale.
  /// If none is supplied then half of the value of staleTime is used
  final Duration refetchInterval;

  /// The Cache that holds all the queries, mutations and infinite queries
  QueryCache cache;

  QueryBowl({
    /// The Cache that holds all the queries, mutations and infinite
    /// queries
    QueryCache? cache,
    this.staleTime = Duration.zero,

    /// global cache time
    ///
    /// Removes inactive queries after provided duration of [cacheTime]
    Duration? cacheTime,
    this.refetchInterval = Duration.zero,
    this.refetchOnMount = false,
    this.refetchOnReconnect = true,
    this.refetchOnReconnectDelay = const Duration(milliseconds: 100),
    this.refetchOnApplicationResumeDelay = const Duration(milliseconds: 100),
    this.refetchOnWindowFocusDelay = const Duration(milliseconds: 100),
    this.refetchOnApplicationResume = true,
    this.refetchOnWindowFocus = true,
    this.refetchOnExternalDataChange = false,
  }) : cache = cache ?? QueryCache(cacheTime: cacheTime) {
    Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) async {
      if (isConnectedToInternet(result)) {
        for (final query in this.cache.queries) {
          if (query.refetchOnReconnect == false || !query.enabled) continue;
          await query.refetch();
          await Future.delayed(refetchOnReconnectDelay);
        }
        for (final infiniteQuery in this.cache.infiniteQueries) {
          if (infiniteQuery.refetchOnReconnect == false ||
              !infiniteQuery.enabled) continue;
          await infiniteQuery.refetchPages();
          await Future.delayed(refetchOnReconnectDelay);
        }
      }
    });

    if (kIsMobile) {
      SystemChannels.lifecycle.setMessageHandler((msg) async {
        if (msg == 'AppLifecycleState.resumed') {
          if (_canNotRefetchAfterWeGotTheApp) return null;
          for (final query in this.cache.queries) {
            if (query.refetchOnApplicationResume == false || !query.enabled)
              continue;
            await query.refetch();
            await Future.delayed(refetchOnApplicationResumeDelay);
          }
          for (final infiniteQuery in this.cache.infiniteQueries) {
            if (infiniteQuery.refetchOnApplicationResume == false ||
                !infiniteQuery.enabled) continue;
            await infiniteQuery.refetchPages();
            await Future.delayed(refetchOnApplicationResumeDelay);
          }
        } else if (msg != null) {
          updateWeLostTheApp();
        }
        return null;
      });
    }
  }

  DateTime? _weLostTheAppAt;

  /// Returns the number of query is currently fetching or refetching
  int get isFetching {
    return cache.queries.fold<int>(
      0,
      (acc, query) {
        if (query.isLoading || query.isRefetching) acc++;
        return acc;
      },
    );
  }

  /// Provides the number of mutations that are running at the moment
  int get isMutating {
    return cache.mutations.fold<int>(
      0,
      (acc, mutation) {
        if (mutation.isLoading) acc++;
        return acc;
      },
    );
  }

  bool get _canNotRefetchAfterWeGotTheApp => (_weLostTheAppAt != null &&
      _weLostTheAppAt!.difference(DateTime.now()) <= cache.cacheTime);

  @protected
  updateWeLostTheApp() {
    _weLostTheAppAt = DateTime.now();
  }

  @protected
  notifyWindowFocused() async {
    if (kIsMobile || _canNotRefetchAfterWeGotTheApp) return;
    for (final query in this.cache.queries) {
      if (query.refetchOnWindowFocus == false || !query.enabled) continue;
      await query.refetch();
      await Future.delayed(refetchOnWindowFocusDelay);
    }
    for (final infiniteQuery in this.cache.infiniteQueries) {
      if (infiniteQuery.refetchOnWindowFocus == false || !infiniteQuery.enabled)
        continue;
      await infiniteQuery.refetchPages();
      await Future.delayed(refetchOnWindowFocusDelay);
    }
  }

  void onQueriesUpdate<T extends Object, Outside>(
    void Function(Query<T, Outside> query) listener,
  ) {
    cache.on((event, changes) {
      if (event == CacheEvent.query && changes is Query<T, Outside>) {
        listener(changes);
      }
    });
  }

  void onMutationsUpdate<T extends Object, Outside>(
    void Function(Mutation<T, Outside> mutation) listener,
  ) {
    cache.on((event, changes) {
      if (event == CacheEvent.mutation && changes is Mutation<T, Outside>) {
        listener(changes);
      }
    });
  }

  void onInfiniteQueriesUpdate<T extends Object, Outside,
      PageParam extends Object>(
    void Function(InfiniteQuery<T, Outside, PageParam> infiniteQuery) listener,
  ) {
    cache.on((event, changes) {
      if (event == CacheEvent.infiniteQuery &&
          changes is InfiniteQuery<T, Outside, PageParam>) {
        listener(changes);
      }
    });
  }

  InfiniteQuery<T, Outside, PageParam>?
      getInfiniteQuery<T extends Object, Outside, PageParam extends Object>(
    String queryKey,
  ) {
    return cache.infiniteQueries.firstWhereOrNull((infiniteQuery) {
      return infiniteQuery.queryKey == queryKey &&
          infiniteQuery is InfiniteQuery<T, Outside, PageParam>;
    })?.cast<InfiniteQuery<T, Outside, PageParam>>();
  }

  /// Get a query by providing queryKey only
  ///
  /// Useful for optimistic update or single query refetch
  Query<T, Outside>? getQuery<T extends Object, Outside>(String queryKey) {
    return cache.queries.firstWhereOrNull((query) {
      return query.queryKey == queryKey && query is Query<T, Outside>;
    })?.cast<Query<T, Outside>>();
  }

  /// Get a mutation by providing mutationKey only
  ///
  /// Useful for mutation resets
  Mutation<T, V>? getMutation<T extends Object, V>(String mutationKey) {
    return cache.mutations.firstWhereOrNull((mutation) {
      return mutation.mutationKey == mutationKey && mutation is Mutation<T, V>;
    })?.cast<Mutation<T, V>>();
  }

  /// Sets [Query]'s data manually
  ///
  /// Mostly used in combination with [onMutate] callback of
  /// [MutationBuilder] & [useMutation] for optimistic updates
  void setQueryData<T extends Object, Outside>(
    String queryKey,
    QueryUpdateFunction<T> updateCb,
  ) {
    getQuery<T, Outside>(queryKey)?.setQueryData(updateCb);
  }

  /// Sets [InfiniteQuery]'s data manually
  ///
  /// Mostly used in combination with [onMutate] callback of
  /// [MutationBuilder] & [useMutation] for optimistic updates
  void
      setInfiniteQueryData<T extends Object, Outside, PageParam extends Object>(
    String queryKey,
    QueryUpdateFunction<Map<PageParam, T?>> updateCb,
  ) {
    getInfiniteQuery<T, Outside, PageParam>(queryKey)?.setQueryData(updateCb);
  }

  /// resets all the queries matching the passed List of queryKeys
  ///
  /// If an empty list of [queryKeys] is passed then all of the queries
  /// will be reset
  void resetQueries(List<String> queryKeys) {
    for (final query in cache.queries) {
      if (queryKeys.isNotEmpty && !queryKeys.contains(query.queryKey)) continue;
      query.reset();
    }
  }

  /// makes all the queries matching the passed List of queryKeys stale
  ///
  /// If an empty list of [queryKeys] is passed then all of the queries
  /// will be invalidated
  void invalidateQueries(List<String> queryKeys) {
    for (final query in cache.queries) {
      if (queryKeys.isNotEmpty && queryKeys.contains(query.queryKey)) continue;
      query.invalidate();
    }
  }

  /// refetches all the queries matching the passed List of queryKeys
  ///
  /// If an empty list of [queryKeys] is passed then all of the queries
  /// will be refetched
  Future<void> refetchQueries(List<String> queryKeys) async {
    for (final query in cache.queries) {
      if (queryKeys.isNotEmpty && queryKeys.contains(query.queryKey)) continue;
      await query.refetch();
    }
  }

  /// Removes all the queries matching the passed List of queryKeys
  /// from the [QueryCache]
  int removeQueries(List<String> queryKeys) {
    int count = 0;
    for (final query in cache.queries) {
      if (queryKeys.isEmpty || !queryKeys.contains(query.queryKey)) continue;
      cache.removeQuery(query);
      count++;
    }
    return count;
  }

  Query<T, Outside> _createQueryWithDefaults<T extends Object, Outside>(
    QueryJob<T, Outside> options,
    Outside externalData, [
    T? previousData,
  ]) {
    final query = Query<T, Outside>.fromOptions(
      options,
      externalData: externalData,
      previousData: previousData,
    );
    query.updateDefaultOptions(
      cacheTime: cache.cacheTime,
      staleTime: staleTime,
      refetchInterval: refetchInterval,
      refetchOnMount: refetchOnMount,
      refetchOnReconnect: refetchOnReconnect,
      refetchOnApplicationResume: refetchOnApplicationResume,
      refetchOnWindowFocus: refetchOnWindowFocus,
    );
    return query;
  }

  InfiniteQuery<T, Outside, PageParam> _createInfiniteQueryWithDefaults<
      T extends Object, Outside, PageParam extends Object>(
    InfiniteQueryJob<T, Outside, PageParam> options,
    Outside externalData,
  ) {
    final infiniteQuery = InfiniteQuery<T, Outside, PageParam>.fromOptions(
      options,
      externalData: externalData,
    );
    infiniteQuery.updateDefaultOptions(
      cacheTime: cache.cacheTime,
      staleTime: staleTime,
      refetchInterval: refetchInterval,
      refetchOnMount: refetchOnMount,
      refetchOnReconnect: refetchOnReconnect,
      refetchOnApplicationResume: refetchOnApplicationResume,
      refetchOnWindowFocus: refetchOnWindowFocus,
    );
    return infiniteQuery;
  }

  /// Creates/Updates a [Query] with the provided [QueryJob] and it's
  /// [externalData] and listeners  and mounts the [QueryBuilder] or
  /// [useQuery] for the Query
  Query<T, Outside> addQuery<T extends Object, Outside>(
    QueryJob<T, Outside> queryJob, {
    required Outside externalData,
    required ValueKey<String> key,
    final QueryListener<T>? onData,
    final QueryListener<dynamic>? onError,
    final T? previousData,
  }) {
    final prevQuery = getQuery<T, Outside>(queryJob.queryKey);
    if (prevQuery != null) {
      // run the query if its still not called or if externalData has
      // changed
      if (!isShallowEqual(
        prevQuery.prevUsedExternalData,
        externalData,
      )) {
        prevQuery.setExternalData(externalData);
      }
      prevQuery.mount(key);
      if (onData != null) prevQuery.addDataListener(onData);
      if (onError != null) prevQuery.addErrorListener(onError);
      // mounting the widget that is using the query in the prevQuery
      return prevQuery;
    }
    final query = _createQueryWithDefaults<T, Outside>(
      queryJob,
      externalData,
      previousData,
    );
    if (onData != null) query.addDataListener(onData);
    if (onError != null) query.addErrorListener(onError);
    query.mount(key);
    cache.addQuery(query);
    return query;
  }

  /// Creates/Updates a [InfiniteQuery] with the provided
  /// [InfiniteQueryJob] and it's [externalData] and listeners and mounts
  /// the [InfiniteQueryBuilder] or [useInfiniteQuery] for the it
  InfiniteQuery<T, Outside, PageParam>
      addInfiniteQuery<T extends Object, Outside, PageParam extends Object>(
    InfiniteQueryJob<T, Outside, PageParam> infiniteQueryJob, {
    required Outside externalData,
    required ValueKey<String> key,
    final InfiniteQueryListeners<T, PageParam>? onData,
    final InfiniteQueryListeners<dynamic, PageParam>? onError,
  }) {
    final prevInfiniteQuery =
        getInfiniteQuery<T, Outside, PageParam>(infiniteQueryJob.queryKey);
    if (prevInfiniteQuery != null) {
      // run the query if its still not called or if externalData has
      // changed
      if (!isShallowEqual(
        prevInfiniteQuery.prevUsedExternalData,
        externalData,
      )) {
        prevInfiniteQuery.setExternalData(externalData);
      }
      prevInfiniteQuery.mount(key);
      if (onData != null) prevInfiniteQuery.addDataListener(onData);
      if (onError != null) prevInfiniteQuery.addErrorListener(onError);
      // mounting the widget that is using the query in the prevQuery
      return prevInfiniteQuery;
    }

    final infiniteQuery =
        _createInfiniteQueryWithDefaults<T, Outside, PageParam>(
      infiniteQueryJob,
      externalData,
    );
    if (onData != null) infiniteQuery.addDataListener(onData);
    if (onError != null) infiniteQuery.addErrorListener(onError);
    infiniteQuery.mount(key);
    cache.addInfiniteQuery(infiniteQuery);
    return infiniteQuery;
  }

  /// Creates/Updates a [Mutation] with the provided
  /// [MutationJob] and it's listeners. Mounts
  /// the [MutationBuilder] or [useMutation] for the it
  Mutation<T, V> addMutation<T extends Object, V>(
    MutationJob<T, V> mutationJob, {
    final MutationListener<T, V>? onData,
    final MutationListener<dynamic, V>? onError,
    final MutationListenerReturnable<V, dynamic>? onMutate,
    required ValueKey<String> key,
  }) {
    final prevMutation = getMutation<T, V>(mutationJob.mutationKey);
    if (prevMutation != null) {
      if (onData != null) prevMutation.addDataListener(onData);
      if (onError != null) prevMutation.addErrorListener(onError);
      if (onMutate != null) prevMutation.addMutateListener(onMutate);
      prevMutation.mount(key);
      return prevMutation;
    } else {
      final mutation = Mutation<T, V>.fromOptions(
        mutationJob,
      );
      if (onData != null) mutation.addDataListener(onData);
      if (onError != null) mutation.addErrorListener(onError);
      if (onMutate != null) mutation.addMutateListener(onMutate);
      mutation.updateDefaultOptions(cacheTime: cache.cacheTime);
      mutation.mount(key);
      cache.addMutation(mutation);
      return mutation;
    }
  }

  /// Creates/Updates a [Query] with the provided [QueryJob] and it's
  /// [externalData] and listeners  and mounts the [QueryBuilder] or
  /// [useQuery] for the Query
  ///
  /// It also fetches/refetches the [Query] strategically/based on changes
  Future<T?> fetchQuery<T extends Object, Outside>(
    QueryJob<T, Outside> options, {
    required Outside externalData,
    final QueryListener<T>? onData,
    final QueryListener<dynamic>? onError,
    required ValueKey<String> key,
  }) async {
    final prevQuery = getQuery<T, Outside>(options.queryKey);
    if (prevQuery != null) {
      // run the query if its still not called or if externalData has
      // changed
      final hasExternalDataChanged = !isShallowEqual(
        prevQuery.prevUsedExternalData,
        externalData,
      );
      prevQuery.mount(key);
      if (onData != null) prevQuery.addDataListener(onData);
      if (onError != null) prevQuery.addErrorListener(onError);
      if (!prevQuery.hasData || hasExternalDataChanged) {
        if (hasExternalDataChanged) prevQuery.setExternalData(externalData);

        return await prevQuery.refetch();
      }
      // mounting the widget that is using the query in the prevQuery
      return prevQuery.data;
    }

    final query = _createQueryWithDefaults<T, Outside>(
      options,
      externalData,
    );

    query.mount(key);
    cache.addQuery(query);
    return await query.fetch();
  }

  /// Finds the closest instance of [QueryBowl] for the provided
  /// [BuildContext]
  static QueryBowl of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<QueryBowlScope>()!.bowl;
  }
}

/// A simple [InheritedWidget] that does the job of injecting [QueryBowl]
/// into context
///
/// ```dart
///  Widget build(BuildContext context) {
///    return QueryBowlScope(
///      bowl: QueryBowl(),
///      child: MaterialApp(/*...other stuff...*/),
///    );
///  }
/// ```
class QueryBowlScope extends InheritedWidget {
  final QueryBowl bowl;

  QueryBowlScope({
    required this.bowl,
    required Widget child,
    Key? key,
  }) : super(
          key: key,
          child: MouseRegion(
            onEnter: (event) {
              bowl.notifyWindowFocused();
            },
            onExit: (event) {
              bowl.updateWeLostTheApp();
            },
            child: child,
          ),
        );

  @override
  bool updateShouldNotify(covariant oldWidget) => false;
}
