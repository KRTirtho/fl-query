import 'package:fl_query/src/collections/json_config.dart';
import 'package:fl_query/src/collections/refresh_config.dart';
import 'package:fl_query/src/collections/retry_config.dart';

typedef QueryJobFn<DataType, ArgsType> = Future<DataType> Function(
    ArgsType args);
typedef QueryJobVariableFn<DataType, ArgsType> = Future<DataType> Function(
  String variableKey,
  ArgsType args,
);

typedef QueryJobVariableKeyFn<DataType, ErrorType, ArgsType>
    = QueryJob<DataType, ErrorType, ArgsType> Function(String variable);

class QueryJob<DataType, ErrorType, ArgsType> {
  final QueryJobFn<DataType, ArgsType> task;
  final String queryKey;

  final DataType? initial;

  final RetryConfig? retryConfig;
  final RefreshConfig? refreshConfig;
  final JsonConfig<DataType>? jsonConfig;

  // widget specific
  final bool enabled;

  const QueryJob({
    required this.queryKey,
    required this.task,
    this.initial,
    this.retryConfig,
    this.refreshConfig,
    this.jsonConfig,
    this.enabled = true,
  }) : assert(
          (jsonConfig != null && enabled) || jsonConfig == null,
          'jsonConfig is only supported when enabled is true',
        );

  static QueryJobVariableKeyFn<DataType, ErrorType, ArgsType>
      withVariableKey<DataType, ErrorType, ArgsType>({
    required String baseQueryKey,
    required QueryJobVariableFn<DataType, ArgsType?> task,
    DataType? initial,
    RetryConfig? retryConfig,
    RefreshConfig? refreshConfig,
    JsonConfig<DataType>? jsonConfig,
    bool enabled = true,
  }) {
    return (String variableKey) => QueryJob(
          queryKey: "$baseQueryKey$variableKey",
          task: (args) => task(variableKey, args),
          initial: initial,
          retryConfig: retryConfig,
          refreshConfig: refreshConfig,
          jsonConfig: jsonConfig,
          enabled: enabled,
        );
  }
}
