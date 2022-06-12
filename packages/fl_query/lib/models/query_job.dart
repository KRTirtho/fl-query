import 'package:fl_query/query.dart';

class QueryJob<T extends Object, Outside> {
  // all params
  final String queryKey;
  QueryTaskFunction<T, Outside> task;
  final int? retries;
  final Duration? retryDelay;
  final T? initialData;

  /// If set to false then the initial fetch will not be called & to
  /// start the process the user has to call the refetch first
  final bool? enabled;

  // got from global options
  final Duration? staleTime;
  final Duration? cacheTime;

  QueryJob({
    required this.queryKey,
    required this.task,
    this.retries,
    this.retryDelay,
    this.initialData,
    this.staleTime,
    this.cacheTime,
    this.enabled,
  });
}
