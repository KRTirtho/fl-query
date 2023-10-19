import 'package:fl_query/fl_query.dart';
import 'package:fl_query_hooks/src/use_mutation.dart';

Mutation<DataType, ErrorType, VariablesType>
    useMutationJob<DataType, ErrorType, VariablesType, RecoveryType, ArgsType>({
  required MutationJob<DataType, ErrorType, VariablesType, RecoveryType,
          ArgsType>
      job,
  MutationOnDataFn<DataType, RecoveryType>? onData,
  MutationOnErrorFn<ErrorType, RecoveryType>? onError,
  MutationOnMutationFn<VariablesType, RecoveryType>? onMutate,
  ArgsType? args,
  List<Object?>? keys,
}) {
  return useMutation(
    job.mutationKey,
    (variables) => job.task(variables, args),
    retryConfig: job.retryConfig,
    onData: onData,
    onError: onError,
    onMutate: onMutate,
    refreshQueries: job.refreshQueries,
    refreshInfiniteQueries: job.refreshInfiniteQueries,
    keys: keys,
  );
}
