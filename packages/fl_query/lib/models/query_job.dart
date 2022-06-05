import 'package:fl_query/query.dart';

class QueryJob<T extends Object, Outside> {
  // all params
  final String queryKey;
  QueryTaskFunction<T, Outside> task;
  final int? retries;
  final Duration? retryDelay;
  final T? initialData;

  // got from global options
  final Duration? staleTime;

  final QueryListener<T>? onData;
  final QueryListener<dynamic>? onError;
  QueryJob({
    required this.queryKey,
    required this.task,
    this.retries,
    this.retryDelay,
    this.initialData,
    this.staleTime,
    this.onData,
    this.onError,
  });
}
