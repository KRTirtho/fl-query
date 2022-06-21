import 'dart:async';

import 'package:fl_query/models/query_job.dart';
import 'package:fl_query/mutation.dart';
import 'package:fl_query/query.dart';
import 'package:collection/collection.dart';
import 'package:fl_query/utils.dart';
import 'package:flutter/widgets.dart';

class QueryBowlScope extends StatefulWidget {
  final Widget child;
  final Duration staleTime;
  final Duration cacheTime;

  // refetching options

  // refetch query when new query instance mounts
  final bool refetchOnMount;
  // for desktop & web only
  final bool refetchOnWindowFocus;
  // for mobile only
  final bool refetchOnApplicationResume;
  // refetch when user's device reconnects to the internet after no being
  // connected before
  final bool refetchOnReconnect;

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
    this.refetchOnApplicationResume = true,
    this.refetchOnWindowFocus = true,
    Key? key,
  }) : super(key: key);

  @override
  State<QueryBowlScope> createState() => _QueryBowlScopeState();
}

class _QueryBowlScopeState extends State<QueryBowlScope> {
  late Set<Query> queries;
  late Set<Mutation> mutations;

  @override
  void initState() {
    super.initState();
    queries = {};
    mutations = {};
  }

  @override
  void dispose() {
    _disposeUpdateListeners();
    super.dispose();
  }

  void _listenToUpdates() {
    for (final query in queries) {
      query.addListener(() => updateQueries(query));
    }
    for (final mutation in mutations) {
      mutation.addListener(() => updateMutations(mutation));
    }
  }

  void _disposeUpdateListeners() {
    for (final query in queries) {
      query.removeListener(() => updateQueries(query));
    }
    for (final mutation in mutations) {
      mutation.removeListener(() => updateMutations(mutation));
    }
  }

  void updateQueries(Query query) {
    setState(() {
      // checking & not including inactive queries
      // basically garbage collecting queries
      queries = Set.from(
        query.isInactive
            ? queries.where((el) => el.queryKey != query.queryKey)
            : queries,
      );
    });
  }

  void updateMutations(Mutation mutation) {
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
  }

  void addQuery<T extends Object, Outside>(Query<T, Outside> query) {
    setState(() {
      queries = Set.from({...queries, query});
    });
  }

  void addMutation<T extends Object, V>(Mutation<T, V> mutation) {
    setState(() {
      mutations = Set.from({...mutations, mutation});
    });
  }

  int removeQueries(List<String> queryKeys) {
    int count = 0;
    setState(() {
      mutations = Set.from(
        queries.whereNot((query) {
          final isAboutToRip = queryKeys.contains(query.queryKey);
          if (isAboutToRip) count++;
          return isAboutToRip;
        }),
      );
    });
    return count;
  }

  void clear() {
    setState(() {
      queries = Set<Query>();
      mutations = Set<Mutation>();
    });
  }

  @override
  Widget build(BuildContext context) {
    _disposeUpdateListeners();
    _listenToUpdates();
    return QueryBowl(
      addQuery: addQuery,
      addMutation: addMutation,
      removeQueries: removeQueries,
      clear: clear,
      queries: queries,
      mutations: mutations,
      staleTime: widget.staleTime,
      cacheTime: widget.cacheTime,
      refetchInterval: widget.refetchInterval,
      refetchOnMount: widget.refetchOnMount,
      child: widget.child,
    );
  }
}

/// QueryBowl holds all the query related methods & properties.
/// Its responsible for creating/updating/delete queries
class QueryBowl extends InheritedWidget {
  final Set<Query> _queries;
  final Set<Mutation> _mutations;
  final Duration staleTime;
  final Duration cacheTime;

  final Duration? refetchInterval;
  final bool refetchOnMount;

  final void Function<T extends Object, Outside>(Query<T, Outside> query)
      _addQuery;

  final void Function<T extends Object, V>(Mutation<T, V> mutation)
      _addMutation;

  final int Function(List<String>) removeQueries;

  final void Function() clear;

  const QueryBowl({
    required Widget child,
    required final void Function<T extends Object, Outside>(
            Query<T, Outside> query)
        addQuery,
    required final void Function<T extends Object, V>(Mutation<T, V> mutation)
        addMutation,
    required final Set<Query> queries,
    required final Set<Mutation> mutations,
    required this.staleTime,
    required this.cacheTime,
    required this.removeQueries,
    required this.clear,
    required this.refetchOnMount,
    this.refetchInterval,
    Key? key,
  })  : _addQuery = addQuery,
        _queries = queries,
        _mutations = mutations,
        _addMutation = addMutation,
        super(child: child, key: key);

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
      if (onData != null) prevQuery.onDataListeners.add(onData);
      if (onError != null) prevQuery.onErrorListeners.add(onError);
      if (!prevQuery.hasData || hasExternalDataChanged) {
        if (hasExternalDataChanged) prevQuery.setExternalData(externalData);
        return prevQuery.fetched
            ? await prevQuery.refetch()
            : await prevQuery.fetch();
      }
      // mounting the widget that is using the query in the prevQuery
      return prevQuery.data;
    }

    /// populating with default configurations
    options.refetchInterval ??= refetchInterval;
    options.staleTime ??= staleTime;
    options.cacheTime ??= cacheTime;
    options.refetchOnMount ??= refetchOnMount;
    final query = Query<T, Outside>.fromOptions(
      options,
      externalData: externalData,
      onData: onData,
      onError: onError,
    );
    query.mount(key);
    _addQuery<T, Outside>(query);
    return await query.fetch();
  }

  @protected
  Query<T, Outside> addQuery<T extends Object, Outside>(
    Query<T, Outside> query, {
    required ValueKey<String> key,
    final QueryListener<T>? onData,
    final QueryListener<dynamic>? onError,
  }) {
    final prevQuery =
        _queries.firstWhereOrNull((q) => q.queryKey == query.queryKey);
    if (prevQuery is Query<T, Outside>) {
      // run the query if its still not called or if externalData has
      // changed
      if (prevQuery.prevUsedExternalData != null &&
          query.externalData != null &&
          !isShallowEqual(
            prevQuery.prevUsedExternalData!,
            query.externalData!,
          )) {
        prevQuery.setExternalData(query.externalData);
      }
      prevQuery.mount(key);
      if (onData != null) prevQuery.onDataListeners.add(onData);
      if (onError != null) prevQuery.onErrorListeners.add(onError);
      // mounting the widget that is using the query in the prevQuery
      return prevQuery;
    }
    if (onData != null) query.onDataListeners.add(onData);
    if (onError != null) query.onErrorListeners.add(onError);
    query.updateDefaultOptions(
      cacheTime: cacheTime,
      staleTime: staleTime,
      refetchInterval: refetchInterval,
      refetchOnMount: refetchOnMount,
    );
    query.mount(key);
    _addQuery<T, Outside>(query);
    return query;
  }

  @protected
  Mutation<T, V> addMutation<T extends Object, V>(
    Mutation<T, V> mutation, {
    final MutationListener<T>? onData,
    final MutationListener<dynamic>? onError,
    final MutationListener<V>? onMutate,
    required ValueKey<String> key,
  }) {
    final prevMutation = _mutations.firstWhereOrNull(
        (prevMutation) => prevMutation.mutationKey == mutation.mutationKey);
    if (prevMutation != null && prevMutation is Mutation<T, V>) {
      if (onData != null) prevMutation.onDataListeners.add(onData);
      if (onError != null) prevMutation.onErrorListeners.add(onError);
      if (onMutate != null) prevMutation.onMutateListeners.add(onMutate);
      prevMutation.mount(key);
      return prevMutation;
    } else {
      mutation.updateDefaultOptions(cacheTime: cacheTime);
      mutation.mount(key);
      _addMutation(mutation);
      return mutation;
    }
  }

  Query<T, Outside>? getQuery<T extends Object, Outside>(String queryKey) {
    return _queries.firstWhereOrNull((query) {
      return query.queryKey == queryKey && query is Query<T, Outside>;
    })?.cast<Query<T, Outside>>();
  }

  Mutation<T, V>? getMutation<T extends Object, V>(String mutationKey) {
    return _mutations.firstWhereOrNull((mutation) {
      return mutation.mutationKey == mutationKey && mutation is Mutation<T, V>;
    })?.cast<Mutation<T, V>>();
  }

  int get isFetching {
    return _queries.fold<int>(
      0,
      (acc, query) {
        if (query.isLoading || query.isRefetching) acc++;
        return acc;
      },
    );
  }

  int get isMutating {
    return _mutations.fold<int>(
      0,
      (acc, mutation) {
        if (mutation.isLoading) acc++;
        return acc;
      },
    );
  }

  void setQueryData<T extends Object, Outside>(
      String queryKey, QueryUpdateFunction<T> updateCb) {
    getQuery<T, Outside>(queryKey)?.setQueryData(updateCb);
  }

  void resetQueries(List<String> queryKeys) {
    for (final query in _queries) {
      if (!queryKeys.contains(query.queryKey)) continue;
      query.reset();
    }
  }

  void invalidateQueries(List<String> queryKeys) {
    for (final query in _queries) {
      if (!queryKeys.contains(query.queryKey)) continue;
      // TODO: Implement Invaldiate Queries
    }
  }

  Future<void> refetchQueries(List<String> queryKeys) async {
    for (final query in _queries) {
      if (!queryKeys.contains(query.queryKey)) continue;
      await query.refetch();
    }
  }

  static QueryBowl of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<QueryBowl>()!;

  @override
  bool updateShouldNotify(QueryBowl oldWidget) {
    return oldWidget.staleTime != staleTime ||
        oldWidget._queries != _queries ||
        oldWidget._mutations != _mutations;
  }
}
