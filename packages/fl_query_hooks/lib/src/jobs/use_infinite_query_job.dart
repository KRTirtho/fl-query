import 'package:fl_query/fl_query.dart';
import 'package:fl_query_hooks/src/use_infinite_query.dart';
import 'package:flutter/material.dart';

InfiniteQuery<DataType, ErrorType, PageType>
    useInfiniteQueryJob<DataType, ErrorType, PageType, ArgsType>({
  required InfiniteQueryJob<DataType, ErrorType, PageType, ArgsType> job,
  ValueChanged<PageEvent<DataType, PageType>>? onData,
  ValueChanged<PageEvent<ErrorType, PageType>>? onError,
  ArgsType? args,
  List<Object?>? keys,
}) {
  return useInfiniteQuery<DataType, ErrorType, PageType>(
    job.queryKey,
    (page) => job.task(page, args),
    initialPage: job.initialPage,
    nextPage: job.nextPage,
    retryConfig: job.retryConfig,
    refreshConfig: job.refreshConfig,
    jsonConfig: job.jsonConfig,
    onData: onData,
    onError: onError,
    enabled: job.enabled,
    keys: keys,
  );
}
