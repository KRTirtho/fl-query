import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fl_query/fl_query.dart';
import 'package:fl_query/src/base_query.dart';
import 'package:fl_query/src/models/query_job.dart';
import 'package:flutter/widgets.dart';

enum QueryStatus {
  /// in times when an error occurs
  /// will get reset to idle on refetch/retry
  error,

  /// when a query successfully executes
  success,

  /// when the query is running (not refetching)
  loading,

  /// when the query isn't yet fetched, re-fetched, or got reset
  /// mostly when both [data] & [error] are null. Also [fetched] is false
  idle,

  /// when the query is refetching (rerunning)
  refetching;
}

typedef QueryTaskFunction<T extends Object, Outside> = FutureOr<T> Function(
  String queryKey,
  Outside externalData,
);

typedef QueryListener<T> = FutureOr<void> Function(T);

typedef ListenerUnsubscriber = void Function();

typedef QueryUpdateFunction<T> = FutureOr<T> Function(T? oldData);

class Query<T extends Object, Outside> extends BaseQuery<T, Outside, dynamic> {
  QueryTaskFunction<T, Outside> task;

  Query({
    required super.queryKey,
    required this.task,
    required super.staleTime,
    required super.cacheTime,
    required super.externalData,
    required super.retries,
    required super.retryDelay,
    required super.queryBowl,
    required super.status,
    super.refetchOnMount,
    super.refetchOnReconnect,
    super.refetchInterval,
    super.enabled,
    super.previousData,
    super.connectivity,
    super.initialData,
    super.onData,
    super.onError,
  });

  Query.fromOptions(
    QueryJob<T, Outside> options, {
    required super.queryBowl,
    required Outside externalData,
    T? previousData,
    QueryListener<T>? onData,
    QueryListener<dynamic>? onError,
  })  : task = options.task,
        super(
          cacheTime: options.cacheTime ?? const Duration(minutes: 5),
          retries: options.retries ?? 3,
          retryDelay: options.retryDelay ?? const Duration(milliseconds: 200),
          externalData: externalData,
          enabled: options.enabled ?? true,
          staleTime: options.staleTime ?? const Duration(milliseconds: 500),
          initialData: options.initialData,
          refetchInterval: options.refetchInterval,
          refetchOnMount: options.refetchOnMount,
          refetchOnReconnect: options.refetchOnReconnect,
          status: previousData == null ? QueryStatus.idle : QueryStatus.success,
          connectivity: options.connectivity ?? Connectivity(),
          previousData: previousData,
          queryKey: options.queryKey,
        );

  @override
  Timer createRefetchTimer() {
    return Timer.periodic(
      refetchInterval!,
      (_) async {
        // only refetch if its connected to the internet or refetch will
        // always result in error while there's no internet
        if (isStale && await isInternetConnected()) await refetch();
      },
    );
  }

  /// can be used to update the data manually. Can be useful when used
  /// together with mutations to perform optimistic updates or manual data
  /// updates
  /// For updating particular queries after a mutation using the
  /// `QueryBowl.refetchQueries` is more appropriate. But this one can be
  /// used when only 1 query needs get updated
  ///
  /// Every time a new instance of data should be returned because of
  /// immutability
  void setQueryData(QueryUpdateFunction<T> updateFn) async {
    final newData = await updateFn(data);
    if (data == newData) return;
    data = newData;
    status = QueryStatus.success;
    notifyListeners();
  }

  String get debugLabel => "Query($queryKey)";

  @override
  void mount(ValueKey<String> uKey) {
    super.mount(uKey);

    /// refetching on mount if it's set to true
    /// also checking if the is stale or not
    /// no need to refetch a valid query for no reason
    if (refetchOnMount == true && isStale) {
      this.isInternetConnected().then((isConnected) async {
        if (isConnected) await refetch();
      });
    }
  }

  @override
  bool operator ==(other) {
    return (other is Query<T, Outside> && other.queryKey == queryKey) ||
        identical(other, this);
  }

  @override
  FutureOr<void> setData() async {
    data = await task(queryKey, externalData);
  }

  @override
  void setError(e) {
    error = e;
  }
}
