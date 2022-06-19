import 'package:fl_query/mutation.dart';

class MutationJob<T extends Object, V> {
  final String mutationKey;
  MutationTaskFunction<T, V> task;
  final int? retries;
  final Duration? retryDelay;
  final Duration? cacheTime;

  MutationJob({
    required this.mutationKey,
    required this.task,
    this.retries,
    this.retryDelay,
    this.cacheTime,
  });
}
