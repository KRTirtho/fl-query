import 'package:fl_query/src/collections/retry_config.dart';

typedef MutationJobFn<DataType, VariablesType, ArgsType> = Future<DataType>
    Function(
  VariablesType variables,
  ArgsType args,
);

typedef MutationJobVariableKeyFn<DataType, ErrorType, VariablesType,
        RecoveryType, ArgsType>
    = MutationJob<DataType, ErrorType, VariablesType, RecoveryType, ArgsType>
        Function(String variable);

class MutationJob<DataType, ErrorType, VariablesType, RecoveryType, ArgsType> {
  final MutationJobFn<DataType, VariablesType, ArgsType?> task;
  final String mutationKey;

  final RetryConfig? retryConfig;

  final List<String>? refreshQueries;
  final List<String>? refreshInfiniteQueries;

  const MutationJob({
    required this.mutationKey,
    required this.task,
    this.retryConfig,
    this.refreshQueries,
    this.refreshInfiniteQueries,
  });

  static MutationJobVariableKeyFn<DataType, ErrorType, VariablesType,
          RecoveryType, ArgsType>
      withVariableKey<DataType, ErrorType, VariablesType, RecoveryType,
          ArgsType>({
    required String baseMutationKey,
    required MutationJobFn<DataType, VariablesType, ArgsType?> task,
    RetryConfig? retryConfig,
    List<String>? refreshQueries,
    List<String>? refreshInfiniteQueries,
  }) {
    return (String variable) => MutationJob(
          mutationKey: "$baseMutationKey$variable",
          task: task,
          retryConfig: retryConfig,
          refreshQueries: refreshQueries,
          refreshInfiniteQueries: refreshInfiniteQueries,
        );
  }
}
