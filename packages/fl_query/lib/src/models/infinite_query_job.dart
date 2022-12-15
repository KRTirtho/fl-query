import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fl_query/src/infinite_query.dart';
import 'package:fl_query/src/models/query_job.dart';
import 'package:flutter/widgets.dart';

class InfiniteQueryJob<T extends Object, Outside, PageParam extends Object> {
  // all params
  String _queryKey;
  InfiniteQueryTaskFunction<T, Outside, PageParam> task;
  SerializeFunction<T>? serialize;
  DeserializeFunction<T>? deserialize;
  SerializeFunction<PageParam>? serializePageParam;
  DeserializeFunction<PageParam>? deserializePageParam;
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
  final bool? refetchOnApplicationResume;
  final bool? refetchOnWindowFocus;
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
    this.refetchOnApplicationResume,
    this.refetchOnWindowFocus,
    this.connectivity,
    this.deserialize,
    this.serialize,
    this.serializePageParam,
    this.deserializePageParam,
  })  : assert(
          serialize == null &&
                  deserialize == null &&
                  serializePageParam == null &&
                  deserializePageParam == null ||
              (serialize != null &&
                  deserialize != null &&
                  serializePageParam != null &&
                  deserializePageParam != null &&
                  enabled != false),
          "All or none of the serialize, deserialize, serializePageParam & deserializePageParam function must be provided. And `enabled` must be true if all of them are provided.",
        ),
        _queryKey = queryKey;

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
    bool? refetchOnApplicationResume,
    bool? refetchOnWindowFocus,
    Connectivity? connectivity,
    SerializeFunction<T>? serialize,
    DeserializeFunction<T>? deserialize,
    SerializeFunction<PageParam>? serializePageParam,
    DeserializeFunction<PageParam>? deserializePageParam,
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
        refetchOnApplicationResume: refetchOnApplicationResume,
        refetchOnWindowFocus: refetchOnWindowFocus,
        connectivity: connectivity,
        initialParam: initialParam,
        serialize: serialize,
        deserialize: deserialize,
        serializePageParam: serializePageParam,
        deserializePageParam: deserializePageParam,
      );
      query.isDynamic = true;
      return query;
    };
  }
}
