import 'dart:async';

import 'package:fl_query/fl_query.dart';
import 'package:fl_query_hooks/src/use_query_client.dart';
import 'package:fl_query_hooks/src/utils/use_updater.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

InfiniteQuery<DataType, ErrorType, PageType>
    useInfiniteQuery<DataType, ErrorType, PageType>(
  String queryKey,
  InfiniteQueryFn<DataType, PageType> queryFn, {
  required InfiniteQueryNextPage<DataType, PageType> nextPage,
  required PageType initialPage,
  RetryConfig? retryConfig,
  RefreshConfig? refreshConfig,
  JsonConfig<DataType>? jsonConfig,
  ValueChanged<PageEvent<DataType, PageType>>? onData,
  ValueChanged<PageEvent<ErrorType, PageType>>? onError,
  bool enabled = true,
  List<Object?>? keys,
}) {
  final rebuild = useUpdater();
  final client = useQueryClient();
  final query = useMemoized<InfiniteQuery<DataType, ErrorType, PageType>>(() {
    final query = client.createInfiniteQuery<DataType, ErrorType, PageType>(
      queryKey,
      queryFn,
      initialParam: initialPage,
      nextPage: nextPage,
      jsonConfig: jsonConfig,
      refreshConfig: refreshConfig,
      retryConfig: retryConfig,
    );
    return query;
  }, [queryKey]);

  useEffect(() {
    return query.addListener(rebuild);
  }, [query]);

  useEffect(() {
    if (enabled) {
      query.fetch();
    }
    return null;
  }, [enabled]);

  useEffect(() {
    query.updateQueryFn(queryFn);
    return null;
  }, [queryFn, query]);

  useEffect(() {
    query.updateNextPageFn(nextPage);
    return null;
  }, [nextPage, query]);

  useEffect(() {
    StreamSubscription<PageEvent<DataType, PageType>>? dataSubscription;
    StreamSubscription<PageEvent<ErrorType, PageType>>? errorSubscription;

    if (onData != null) {
      dataSubscription = query.dataStream.listen(onData);
    }
    if (onError != null) {
      errorSubscription = query.errorStream.listen(onError);
    }

    return () {
      dataSubscription?.cancel();
      errorSubscription?.cancel();
    };
  }, [onData, onError, query]);

  return query;
}
