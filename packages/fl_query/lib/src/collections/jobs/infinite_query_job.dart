import 'package:fl_query/src/collections/json_config.dart';
import 'package:fl_query/src/collections/refresh_config.dart';
import 'package:fl_query/src/collections/retry_config.dart';
import 'package:fl_query/src/core/infinite_query.dart';

typedef InfiniteQueryJobFn<DataType, PageType, ArgsType> = Future<DataType>
    Function(PageType page, ArgsType args);

typedef InfiniteQueryJobVariableKeyFn<DataType, ErrorType, PageType, ArgsType>
    = InfiniteQueryJob<DataType, ErrorType, PageType, ArgsType> Function(
        String variable);

class InfiniteQueryJob<DataType, ErrorType, PageType, ArgsType> {
  final InfiniteQueryJobFn<DataType, PageType, ArgsType?> task;
  final String queryKey;

  final PageType initialPage;
  final InfiniteQueryNextPage<DataType, PageType> nextPage;

  final RetryConfig? retryConfig;
  final RefreshConfig? refreshConfig;
  final JsonConfig<DataType>? jsonConfig;

  final bool enabled;

  const InfiniteQueryJob({
    required this.queryKey,
    required this.task,
    required this.nextPage,
    required this.initialPage,
    this.retryConfig,
    this.refreshConfig,
    this.jsonConfig,
    this.enabled = true,
  }) : assert(
          (jsonConfig != null && enabled) || jsonConfig == null,
          'jsonConfig is only supported when enabled is true',
        );

  static InfiniteQueryJobVariableKeyFn<DataType, ErrorType, PageType, ArgsType>
      withVariableKey<DataType, ErrorType, PageType, ArgsType>({
    required String baseQueryKey,
    required InfiniteQueryJobFn<DataType, PageType, ArgsType?> task,
    required final InfiniteQueryNextPage<DataType, PageType> nextPage,
    required final PageType initialPage,
    RetryConfig? retryConfig,
    RefreshConfig? refreshConfig,
    JsonConfig<DataType>? jsonConfig,
    bool enabled = true,
  }) {
    return (String variable) => InfiniteQueryJob(
          queryKey: "$baseQueryKey$variable",
          task: task,
          nextPage: nextPage,
          initialPage: initialPage,
          retryConfig: retryConfig,
          refreshConfig: refreshConfig,
          jsonConfig: jsonConfig,
          enabled: enabled,
        );
  }
}
