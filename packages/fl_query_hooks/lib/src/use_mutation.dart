import 'dart:async';

import 'package:fl_query/fl_query.dart';
import 'package:fl_query_hooks/src/use_query_client.dart';
import 'package:fl_query_hooks/src/utils/use_updater.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

Mutation<DataType, ErrorType, VariablesType>
    useMutation<DataType, ErrorType, VariablesType, RecoveryType>(
  String mutationKey,
  MutationFn<DataType, VariablesType> mutationFn, {
  RetryConfig retryConfig = DefaultConstants.retryConfig,
  MutationOnDataFn<DataType, RecoveryType>? onData,
  MutationOnErrorFn<ErrorType, RecoveryType>? onError,
  MutationOnMutationFn<VariablesType, RecoveryType>? onMutate,
  List<String>? refreshQueries,
  List<String>? refreshInfiniteQueries,
  List<Object?>? keys,
}) {
  final rebuild = useUpdater();
  final client = useQueryClient();
  final mutation =
      useMemoized<Mutation<DataType, ErrorType, VariablesType>>(() {
    return client.createMutation<DataType, ErrorType, VariablesType>(
      mutationKey,
      mutationFn,
      retryConfig: retryConfig,
    );
  }, [mutationKey]);

  final recoveryData = useState<RecoveryType?>(null);

  useEffect(() {
    return mutation.addListener(rebuild);
  }, [mutation]);

  useEffect(() {
    mutation.updateMutationFn(mutationFn);
    return null;
  }, [mutationFn, mutation]);

  useEffect(() {
    if (onMutate != null) {
      return mutation.mutationStream.listen((event) async {
        recoveryData.value = await onMutate.call(event);
      }).cancel;
    }
    return null;
  }, [onMutate, mutation]);

  useEffect(() {
    StreamSubscription<DataType>? dataSubscription;
    StreamSubscription<ErrorType>? errorSubscription;

    dataSubscription = mutation.dataStream.listen((event) {
      final data = onData?.call(event, recoveryData.value);
      if (refreshQueries != null) {
        client.refreshQueries(refreshQueries);
      }
      if (refreshInfiniteQueries != null) {
        client.refreshInfiniteQueries(refreshInfiniteQueries);
      }
      return data;
    });

    if (onError != null) {
      errorSubscription = mutation.errorStream.listen(
        (event) {
          return onError(event, recoveryData.value);
        },
      );
    }

    return () {
      dataSubscription?.cancel();
      errorSubscription?.cancel();
    };
  }, [onData, onError, recoveryData.value, mutation]);

  return mutation;
}
