import 'package:fl_query/src/query.dart';

/// How to make dependent Queries?
///
/// Pass a [QueryBowl] class/object to [task] that contains a method
/// [QueryBowl.dependOnQuery] that takes a [QueryJob] and uses that to get
/// the appropriate query for it or if it doesn't exist creates a new
/// instance. It listens to the changes of [Query] of the passed
/// [QueryJob] & calls the [notifyListener] method of running [Query]
///
/// If shown briefly
///
/// ```data
/// task: (queryKey, external, queryBowl){
/// final dependentQuery = queryBowl.dependOnQuery(dependentQueryJob);
/// return someAsyncTask();
/// }
/// ```

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
  bool? refetchOnReconnect;
  bool? refetchOnExternalDataChange;
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
    this.refetchOnReconnect,
    this.refetchOnExternalDataChange,
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
        refetchOnReconnect: refetchOnReconnect,
        refetchOnExternalDataChange: refetchOnExternalDataChange,
      );
    };
  }
}
