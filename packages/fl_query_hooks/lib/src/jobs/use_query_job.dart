import 'package:fl_query/fl_query.dart';
import 'package:fl_query_hooks/src/use_query.dart';
import 'package:flutter/material.dart';

Query<DataType, ErrorType> useQueryJob<DataType, ErrorType, ArgsType>({
  required QueryJob<DataType, ErrorType, ArgsType> job,
  ValueChanged<DataType>? onData,
  ValueChanged<ErrorType>? onError,
  ArgsType? args,
}) {
  return useQuery<DataType, ErrorType>(
    job.queryKey,
    () => job.task(args),
    initial: job.initial,
    retryConfig: job.retryConfig,
    refreshConfig: job.refreshConfig,
    jsonConfig: job.jsonConfig,
    onData: onData,
    onError: onError,
    enabled: job.enabled,
  );
}
