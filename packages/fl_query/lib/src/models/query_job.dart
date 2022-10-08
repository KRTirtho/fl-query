import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fl_query/src/query.dart';
import 'package:flutter/widgets.dart';

class QueryJob<T extends Object, Outside> {
  // all params
  String _queryKey;
  QueryTaskFunction<T, Outside> task;
  final int? retries;
  final Duration? retryDelay;
  T? initialData;

  /// If set to false then the initial fetch will not be called & to
  /// start the process the user has to call the refetch first
  final bool? enabled;

  // got from global options
  final bool? refetchOnMount;
  final bool? refetchOnReconnect;
  final bool? refetchOnExternalDataChange;
  final bool? refetchOnApplicationResume;
  final bool? refetchOnWindowFocus;
  final bool? keepPreviousData;
  final Duration? staleTime;
  final Duration? cacheTime;

  final Duration? refetchInterval;
  final Connectivity? connectivity;

  @protected
  bool isDynamic = false;

  QueryJob({
    required String queryKey,
    required this.task,
    this.retries,
    this.retryDelay,
    this.initialData,
    this.staleTime,
    this.cacheTime,
    this.enabled,
    this.refetchInterval,
    this.refetchOnMount,
    this.refetchOnReconnect,
    this.refetchOnExternalDataChange,
    this.connectivity,
    this.keepPreviousData,
    this.refetchOnApplicationResume,
    this.refetchOnWindowFocus,
  }) : _queryKey = queryKey;

  String get queryKey => _queryKey;

  static QueryJob<T, Outside> Function(String queryKey)
      withVariableKey<T extends Object, Outside>({
    required QueryTaskFunction<T, Outside> task,

    /// a extra key joined with queryKey by a '#'
    ///
    /// useful for matching a group query
    String? preQueryKey,
    int? retries,
    Duration? retryDelay,
    T? initialData,
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
    bool? keepPreviousData,
  }) {
    return (String queryKey) {
      if (preQueryKey != null) queryKey = "$preQueryKey#$queryKey";
      final query = QueryJob<T, Outside>(
        queryKey: queryKey,
        task: task,
        retries: retries,
        retryDelay: retryDelay,
        initialData: initialData,
        staleTime: staleTime,
        cacheTime: cacheTime,
        enabled: enabled,
        refetchInterval: refetchInterval,
        refetchOnMount: refetchOnMount,
        refetchOnReconnect: refetchOnReconnect,
        refetchOnExternalDataChange: refetchOnExternalDataChange,
        connectivity: connectivity,
        keepPreviousData: keepPreviousData,
        refetchOnApplicationResume: refetchOnApplicationResume,
        refetchOnWindowFocus: refetchOnWindowFocus,
      );
      query.isDynamic = true;
      return query;
    };
  }
}
