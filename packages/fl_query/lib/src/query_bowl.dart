import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fl_query/src/infinite_query.dart';
import 'package:fl_query/src/models/infinite_query_job.dart';
import 'package:fl_query/src/models/mutation_job.dart';
import 'package:fl_query/src/models/query_job.dart';
import 'package:fl_query/src/mutation.dart';
import 'package:fl_query/src/mutation_builder.dart';
import 'package:fl_query/src/query.dart';
import 'package:fl_query/src/utils.dart';
import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';

/// The widget that holds & provides every [Query] & [Mutation] to your
/// entire Flutter application in anywhere
/// This must be used on the above any other widget
///
/// ```dart
///  Widget build(BuildContext context) {
///    return QueryBowlScope(
///      child: MaterialApp(/*...other stuff...*/),
///    );
///  }
/// ```
///
class QueryBowlScope extends StatefulWidget {
  final Widget child;

  /// global stale time
  ///
  /// Makes [Query.data] stale after crossing the duration of provided
  /// [staleTime]
  final Duration staleTime;

  /// global cache time
  ///
  /// Removes inactive queries after provided duration of [cacheTime]
  final Duration cacheTime;

  // refetching options

  /// refetch query when new query instance mounts
  final bool refetchOnMount;

  /// for desktop & web only (DUMMY & isn't implemented yet)
  final bool refetchOnWindowFocus;

  /// for mobile only (DUMMY & isn't implemented yet)
  final bool refetchOnApplicationResume;

  /// refetch when user's device reconnects to the internet after no being
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

  const QueryBowlScope({
    required this.child,
    this.staleTime = Duration.zero,
    this.cacheTime = const Duration(minutes: 5),
    this.refetchInterval = Duration.zero,
    this.refetchOnMount = false,
    this.refetchOnReconnect = true,
    this.refetchOnReconnectDelay = const Duration(milliseconds: 100),
    this.refetchOnApplicationResume = true,
    this.refetchOnWindowFocus = true,
    this.refetchOnExternalDataChange = false,
    Key? key,
  }) : super(key: key);

  @override
  State<QueryBowlScope> createState() => _QueryBowlScopeState();
}

class _QueryBowlScopeState extends State<QueryBowlScope> {
  late Set<InfiniteQuery> infiniteQueries;
  late Set<Query> queries;
  late Set<Mutation> mutations;

  StreamSubscription<ConnectivityResult>? _connectionStatusSubscription;

  @override
  void initState() {
    super.initState();
    infiniteQueries = {};
    queries = {};
    mutations = {};

    _connectionStatusSubscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) async {
      if (isConnectedToInternet(result)) {
        for (final query in queries) {
          if (query.refetchOnReconnect == false || !query.enabled) continue;
          await query.refetch();
          await Future.delayed(widget.refetchOnReconnectDelay);
        }
        for (final infiniteQuery in infiniteQueries) {
          if (infiniteQuery.refetchOnReconnect == false ||
              !infiniteQuery.enabled) continue;
          await infiniteQuery.refetchPages();
          await Future.delayed(widget.refetchOnReconnectDelay);
        }
      }
    });
  }

  @override
  void dispose() {
    _disposeUpdateListeners();
    _connectionStatusSubscription?.cancel();
    super.dispose();
  }

  void _listenToUpdates() {
    for (final infiniteQuery in infiniteQueries) {
      infiniteQuery.addListener(() => updateInfiniteQueries(infiniteQuery));
    }
    for (final query in queries) {
      query.addListener(() => updateQueries(query));
    }
    for (final mutation in mutations) {
      mutation.addListener(() => updateMutations(mutation));
    }
  }

  void _disposeUpdateListeners() {
    for (final infiniteQuery in infiniteQueries) {
      infiniteQuery.removeListener(() => updateInfiniteQueries(infiniteQuery));
    }
    for (final query in queries) {
      query.removeListener(() => updateQueries(query));
    }
    for (final mutation in mutations) {
      mutation.removeListener(() => updateMutations(mutation));
    }
  }

  void updateQueries(Query query) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // checking & not including inactive queries
      // basically garbage collecting queries
      setState(() {
        queries = Set.from(
          query.isInactive
              ? queries.where((el) => el.queryKey != query.queryKey)
              : queries,
        );
      });
    });
  }

  void updateInfiniteQueries(InfiniteQuery infiniteQuery) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // checking & not including inactive queries
      // basically garbage collecting queries
      setState(() {
        infiniteQueries = Set.from(
          infiniteQuery.isInactive
              ? infiniteQueries
                  .where((el) => el.queryKey != infiniteQuery.queryKey)
              : infiniteQueries,
        );
      });
    });
  }

  void updateMutations(Mutation mutation) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        // checking & not including inactive mutations
        // basically garbage collecting mutations
        mutations = Set.from(
          mutation.isInactive
              ? mutations.where(
                  (el) => el.mutationKey != mutation.mutationKey,
                )
              : mutations,
        );
      });
    });
  }

  void addInfiniteQuery<T extends Object, Outside, PageParam extends Object>(
      InfiniteQuery<T, Outside, PageParam> infiniteQuery) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        infiniteQueries = Set.from({...infiniteQueries, infiniteQuery});
      });
    });
  }

  void addQuery<T extends Object, Outside>(Query<T, Outside> query) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        queries = Set.from({...queries, query});
      });
    });
  }

  void addMutation<T extends Object, V>(Mutation<T, V> mutation) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        mutations = Set.from({...mutations, mutation});
      });
    });
  }

  int removeQueries(List<String> queryKeys) {
    int count = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        mutations = Set.from(
          queries.whereNot((query) {
            final isAboutToRip = queryKeys.contains(query.queryKey);
            if (isAboutToRip) count++;
            return isAboutToRip;
          }),
        );
      });
    });
    return count;
  }

  void clear() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        queries = Set<Query>();
        mutations = Set<Mutation>();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    _disposeUpdateListeners();
    _listenToUpdates();
    return QueryBowl(
      addInfiniteQuery: addInfiniteQuery,
      addQuery: addQuery,
      addMutation: addMutation,
      removeQueries: removeQueries,
      clear: clear,
      infiniteQueries: infiniteQueries,
      queries: queries,
      mutations: mutations,
      staleTime: widget.staleTime,
      cacheTime: widget.cacheTime,
      refetchInterval: widget.refetchInterval,
      refetchOnMount: widget.refetchOnMount,
      refetchOnReconnect: widget.refetchOnReconnect,
      refetchOnExternalDataChange: widget.refetchOnExternalDataChange,
      child: widget.child,
    );
  }
}

/// QueryBowl provides an imperative way to handle all the query &
/// mutation related methods & properties.
///
/// Its responsible or can be used for (not recommended) creating,
/// updating & deleting queries & mutations
class QueryBowl extends InheritedWidget {
  final Set<InfiniteQuery> _infiniteQueries;
  final Set<Query> _queries;
  final Set<Mutation> _mutations;
  final Duration staleTime;
  final Duration cacheTime;

  final Duration? refetchInterval;
  final bool refetchOnMount;
  final bool refetchOnReconnect;
  final bool refetchOnExternalDataChange;

  final void Function<T extends Object, Outside, PageParam extends Object>(
      InfiniteQuery<T, Outside, PageParam> infiniteQuery) _addInfiniteQuery;

  final void Function<T extends Object, Outside>(Query<T, Outside> query)
      _addQuery;

  final void Function<T extends Object, V>(Mutation<T, V> mutation)
      _addMutation;

  final int Function(List<String>) removeQueries;

  final void Function() clear;

  const QueryBowl({
    required Widget child,
    required final void Function<T extends Object, Outside,
                PageParam extends Object>(
            InfiniteQuery<T, Outside, PageParam> infiniteQuery)
        addInfiniteQuery,
    required final void Function<T extends Object, Outside>(
            Query<T, Outside> query)
        addQuery,
    required final void Function<T extends Object, V>(Mutation<T, V> mutation)
        addMutation,
    required final Set<InfiniteQuery> infiniteQueries,
    required final Set<Query> queries,
    required final Set<Mutation> mutations,
    required this.staleTime,
    required this.cacheTime,
    required this.removeQueries,
    required this.clear,
    required this.refetchOnMount,
    required this.refetchOnReconnect,
    required this.refetchOnExternalDataChange,
    this.refetchInterval,
    Key? key,
  })  : _addQuery = addQuery,
        _queries = queries,
        _mutations = mutations,
        _addMutation = addMutation,
        _addInfiniteQuery = addInfiniteQuery,
        _infiniteQueries = infiniteQueries,
        super(child: child, key: key);

  Query<T, Outside> _createQueryWithDefaults<T extends Object, Outside>(
    QueryJob<T, Outside> options,
    Outside externalData, [
    T? previousData,
  ]) {
    final query = Query<T, Outside>.fromOptions(
      options,
      externalData: externalData,
      previousData: previousData,
      queryBowl: this,
    );
    query.updateDefaultOptions(
      cacheTime: cacheTime,
      staleTime: staleTime,
      refetchInterval: refetchInterval,
      refetchOnMount: refetchOnMount,
      refetchOnReconnect: refetchOnReconnect,
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
      queryBowl: this,
    );
    infiniteQuery.updateDefaultOptions(
      cacheTime: cacheTime,
      staleTime: staleTime,
      refetchInterval: refetchInterval,
      refetchOnMount: refetchOnMount,
      refetchOnReconnect: refetchOnReconnect,
    );
    return infiniteQuery;
  }

  Future<T?> prefetchQuery<T extends Object, Outside>(
    QueryJob<T, Outside> options, {
    required Outside externalData,
  }) async {
    final prevQuery =
        _queries.firstWhereOrNull((q) => q.queryKey == options.queryKey);
    if (prevQuery != null && prevQuery is Query<T, Outside>)
      return prevQuery.data;

    final query = _createQueryWithDefaults<T, Outside>(options, externalData);
    _addQuery<T, Outside>(query);
    return await query.fetch();
  }

  /// !⚠️**Warning** only for internal library usage
  @protected
  Future<T?> fetchQuery<T extends Object, Outside>(
    QueryJob<T, Outside> options, {
    required Outside externalData,
    final QueryListener<T>? onData,
    final QueryListener<dynamic>? onError,
    required ValueKey<String> key,
  }) async {
    final prevQuery =
        _queries.firstWhereOrNull((q) => q.queryKey == options.queryKey);
    if (prevQuery is Query<T, Outside>) {
      // run the query if its still not called or if externalData has
      // changed
      final hasExternalDataChanged = prevQuery.prevUsedExternalData != null &&
          externalData != null &&
          !isShallowEqual(
            prevQuery.prevUsedExternalData!,
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

    final query = _createQueryWithDefaults<T, Outside>(options, externalData);
    query.mount(key);
    _addQuery<T, Outside>(query);
    return await query.fetch();
  }

  @protected
  InfiniteQuery<T, Outside, PageParam>
      addInfiniteQuery<T extends Object, Outside, PageParam extends Object>(
    InfiniteQueryJob<T, Outside, PageParam> infiniteQueryJob, {
    required Outside externalData,
    required ValueKey<String> key,
    final QueryListener<T>? onData,
    final QueryListener<dynamic>? onError,
  }) {
    final prevInfiniteQuery = _infiniteQueries.firstWhereOrNull(
      (q) => q.queryKey == infiniteQueryJob.queryKey,
    );
    if (prevInfiniteQuery is InfiniteQuery<T, Outside, PageParam>) {
      // run the query if its still not called or if externalData has
      // changed
      if (prevInfiniteQuery.prevUsedExternalData != null &&
          externalData != null &&
          !isShallowEqual(
            prevInfiniteQuery.prevUsedExternalData!,
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
    _addInfiniteQuery<T, Outside, PageParam>(infiniteQuery);
    return infiniteQuery;
  }

  /// !⚠️**Warning** only for internal library usage
  @protected
  Query<T, Outside> addQuery<T extends Object, Outside>(
    QueryJob<T, Outside> queryJob, {
    required Outside externalData,
    required ValueKey<String> key,
    final QueryListener<T>? onData,
    final QueryListener<dynamic>? onError,
    final T? previousData,
  }) {
    final prevQuery =
        _queries.firstWhereOrNull((q) => q.queryKey == queryJob.queryKey);
    if (prevQuery is Query<T, Outside>) {
      // run the query if its still not called or if externalData has
      // changed
      if (prevQuery.prevUsedExternalData != null &&
          externalData != null &&
          !isShallowEqual(
            prevQuery.prevUsedExternalData!,
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
    _addQuery<T, Outside>(query);
    return query;
  }

  /// !⚠️**Warning** only for internal library usage
  @protected
  Mutation<T, V> addMutation<T extends Object, V>(
    MutationJob<T, V> mutationJob, {
    final MutationListener<T, V>? onData,
    final MutationListener<dynamic, V>? onError,
    final MutationListenerReturnable<V, dynamic>? onMutate,
    required ValueKey<String> key,
  }) {
    final prevMutation = _mutations.firstWhereOrNull(
        (prevMutation) => prevMutation.mutationKey == mutationJob.mutationKey);
    if (prevMutation != null && prevMutation is Mutation<T, V>) {
      if (onData != null) prevMutation.addDataListener(onData);
      if (onError != null) prevMutation.addErrorListener(onError);
      if (onMutate != null) prevMutation.addMutateListener(onMutate);
      prevMutation.mount(key);
      return prevMutation;
    } else {
      final mutation = Mutation<T, V>.fromOptions(
        mutationJob,
        queryBowl: this,
      );
      if (onData != null) mutation.addDataListener(onData);
      if (onError != null) mutation.addErrorListener(onError);
      if (onMutate != null) mutation.addMutateListener(onMutate);
      mutation.updateDefaultOptions(cacheTime: cacheTime);
      mutation.mount(key);
      _addMutation(mutation);
      return mutation;
    }
  }

  InfiniteQuery<T, Outside, PageParam>?
      getInfiniteQuery<T extends Object, Outside, PageParam extends Object>(
    String queryKey,
  ) {
    return _infiniteQueries.firstWhereOrNull((infiniteQuery) {
      return infiniteQuery.queryKey == queryKey &&
          infiniteQuery is InfiniteQuery<T, Outside, PageParam>;
    })?.cast<InfiniteQuery<T, Outside, PageParam>>();
  }

  /// Get a query by providing queryKey only
  ///
  /// Useful for optimistic update or single query refetch
  Query<T, Outside>? getQuery<T extends Object, Outside>(String queryKey) {
    return _queries.firstWhereOrNull((query) {
      return query.queryKey == queryKey && query is Query<T, Outside>;
    })?.cast<Query<T, Outside>>();
  }

  /// Get a mutation by providing mutationKey only
  ///
  /// Useful for mutation resets
  Mutation<T, V>? getMutation<T extends Object, V>(String mutationKey) {
    return _mutations.firstWhereOrNull((mutation) {
      return mutation.mutationKey == mutationKey && mutation is Mutation<T, V>;
    })?.cast<Mutation<T, V>>();
  }

  /// Returns the number of query is currently fetching or refetching
  int get isFetching {
    return _queries.fold<int>(
      0,
      (acc, query) {
        if (query.isLoading || query.isRefetching) acc++;
        return acc;
      },
    );
  }

  /// Provides the number of mutations that are running at the moment
  int get isMutating {
    return _mutations.fold<int>(
      0,
      (acc, mutation) {
        if (mutation.isLoading) acc++;
        return acc;
      },
    );
  }

  /// Sets [Query]'s data manually
  ///
  /// Mostly used in combination with [onMutate] callback of
  /// [MutationBuilder] & [useMutation] for optimistic updates
  void setQueryData<T extends Object, Outside>(
      String queryKey, QueryUpdateFunction<T> updateCb) {
    getQuery<T, Outside>(queryKey)?.setQueryData(updateCb);
  }

  /// resets all the queries matching the passed List of queryKeys
  ///
  /// If an empty list of [queryKeys] is passed then all of the queries
  /// will be reset
  void resetQueries(List<String> queryKeys) {
    for (final query in _queries) {
      if (queryKeys.isNotEmpty && !queryKeys.contains(query.queryKey)) continue;
      query.reset();
    }
  }

  /// makes all the queries matching the passed List of queryKeys stale
  ///
  /// If an empty list of [queryKeys] is passed then all of the queries
  /// will be invalidated
  void invalidateQueries(List<String> queryKeys) {
    for (final query in _queries) {
      if (queryKeys.isNotEmpty && queryKeys.contains(query.queryKey)) continue;
      query.invalidate();
    }
  }

  /// refetches all the queries matching the passed List of queryKeys
  ///
  /// If an empty list of [queryKeys] is passed then all of the queries
  /// will be refetched
  Future<void> refetchQueries(List<String> queryKeys) async {
    for (final query in _queries) {
      if (queryKeys.isNotEmpty && queryKeys.contains(query.queryKey)) continue;
      await query.refetch();
    }
  }

  static QueryBowl of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<QueryBowl>()!;

  /// !⚠️**Warning** only for internal library usage
  @override
  @protected
  bool updateShouldNotify(QueryBowl oldWidget) {
    return oldWidget.staleTime != staleTime ||
        oldWidget._queries != _queries ||
        oldWidget._mutations != _mutations ||
        oldWidget._infiniteQueries != _infiniteQueries;
  }
}
