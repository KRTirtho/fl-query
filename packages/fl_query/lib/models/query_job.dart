import 'package:fl_query/query.dart';

class QueryJob<T extends Object, Outside> {
  // all params
  String _queryKey;
  QueryTaskFunction<T, Outside> task;
  final int? retries;
  final Duration? retryDelay;
  final T? initialData;

  /// If set to false then the initial fetch will not be called & to
  /// start the process the user has to call the refetch first
  final bool? enabled;

  // got from global options
  bool? refetchOnMount;
  Duration? staleTime;
  Duration? cacheTime;

  Duration? refetchInterval;

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
  }) {
    return (String queryKey) {
      if (preQueryKey != null) queryKey = "$preQueryKey#$queryKey";
      return QueryJob<T, Outside>(
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
      );
    };
  }
}
