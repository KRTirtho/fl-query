import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fl_query/fl_query.dart';

class MutationJob<T extends Object, V> {
  String _mutationKey;
  MutationTaskFunction<T, V> task;
  final int? retries;
  final Duration? retryDelay;
  final Duration? cacheTime;
  final Connectivity? connectivity;

  MutationJob({
    required String mutationKey,
    required this.task,
    this.connectivity,
    this.retries,
    this.retryDelay,
    this.cacheTime,
  }) : _mutationKey = mutationKey;

  String get mutationKey => _mutationKey;

  static MutationJob<T, V> Function(String queryKey)
      withVariableKey<T extends Object, V>({
    required MutationTaskFunction<T, V> task,

    /// a extra key joined with mutationKey by a '#'
    ///
    /// useful for matching a group mutation
    String? preMutationKey,
    int? retries,
    Duration? retryDelay,
    Duration? cacheTime,
    Connectivity? connectivity,
  }) {
    return (String mutationKey) {
      if (preMutationKey != null) mutationKey = "$preMutationKey#$mutationKey";
      return MutationJob<T, V>(
        mutationKey: mutationKey,
        task: task,
        retries: retries,
        retryDelay: retryDelay,
        cacheTime: cacheTime,
        connectivity: connectivity,
      );
    };
  }
}
