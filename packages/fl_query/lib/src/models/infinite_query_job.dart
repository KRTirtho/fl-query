import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fl_query/src/infinite_query.dart';
import 'package:flutter/widgets.dart';

class InfiniteQueryJob<T extends Object, Outside, PageParam extends Object> {
  // all params
  String _queryKey;
  InfiniteQueryTaskFunction<T, Outside, PageParam> task;
  final int? retries;
  final Duration? retryDelay;
  T? initialPage;
  PageParam initialParam;

  /// If set to false then the initial fetch will not be called & to
  /// start the process the user has to call the refetch first
  final bool? enabled;

  // got from global options
  final bool? refetchOnMount;
  final bool? refetchOnReconnect;
  final bool? refetchOnExternalDataChange;
  final bool? keepPreviousData;
  final Duration? staleTime;
  final Duration? cacheTime;

  final Duration? refetchInterval;
  final Connectivity? connectivity;
  final InfiniteQueryPageParamFunction<T, PageParam> getNextPageParam;
  final InfiniteQueryPageParamFunction<T, PageParam> getPreviousPageParam;

  @protected
  bool isDynamic = false;

  InfiniteQueryJob({
    required String queryKey,
    required this.task,
    required this.initialParam,
    required this.getNextPageParam,
    required this.getPreviousPageParam,
    this.retries,
    this.retryDelay,
    this.initialPage,
    this.staleTime,
    this.cacheTime,
    this.enabled,
    this.refetchInterval,
    this.refetchOnMount,
    this.refetchOnReconnect,
    this.refetchOnExternalDataChange,
    this.connectivity,
    this.keepPreviousData,
  }) : _queryKey = queryKey;

  String get queryKey => _queryKey;

  static InfiniteQueryJob<T, Outside, PageParam> Function(String queryKey)
      withVariableKey<T extends Object, Outside, PageParam extends Object>({
    required InfiniteQueryTaskFunction<T, Outside, PageParam> task,
    required InfiniteQueryPageParamFunction<T, PageParam> getNextPageParam,
    required InfiniteQueryPageParamFunction<T, PageParam> getPreviousPageParam,
    required PageParam initialParam,

    /// a extra key joined with queryKey by a '#'
    ///
    /// useful for matching a group query
    String? preQueryKey,
    int? retries,
    Duration? retryDelay,
    T? initialPage,
    Duration? staleTime,
    Duration? cacheTime,
    bool? enabled,
    Duration? refetchInterval,
    bool? refetchOnMount,
    bool? refetchOnReconnect,
    bool? refetchOnExternalDataChange,
    Connectivity? connectivity,
    bool? keepPreviousData,
  }) {
    return (String queryKey) {
      if (preQueryKey != null) queryKey = "$preQueryKey#$queryKey";
      final query = InfiniteQueryJob<T, Outside, PageParam>(
        queryKey: queryKey,
        task: task,
        getNextPageParam: getNextPageParam,
        getPreviousPageParam: getPreviousPageParam,
        retries: retries,
        retryDelay: retryDelay,
        initialPage: initialPage,
        staleTime: staleTime,
        cacheTime: cacheTime,
        enabled: enabled,
        refetchInterval: refetchInterval,
        refetchOnMount: refetchOnMount,
        refetchOnReconnect: refetchOnReconnect,
        refetchOnExternalDataChange: refetchOnExternalDataChange,
        connectivity: connectivity,
        keepPreviousData: keepPreviousData,
        initialParam: initialParam,
      );
      query.isDynamic = true;
      return query;
    };
  }
}
