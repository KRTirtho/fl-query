import 'dart:async';

import 'package:fl_query/fl_query.dart';
import 'package:fl_query_hooks/src/use_query_client.dart';
import 'package:fl_query_hooks/src/utils/use_updater.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

Query<DataType, ErrorType> useQuery<DataType, ErrorType>(
  final String queryKey,
  final QueryFn<DataType> queryFn, {
  final DataType? initial,
  final RetryConfig? retryConfig,
  final RefreshConfig? refreshConfig,
  final JsonConfig<DataType>? jsonConfig,
  final ValueChanged<DataType>? onData,
  final ValueChanged<ErrorType>? onError,

  // hook specific
  final bool enabled = true,
}) {
  final rebuild = useUpdater();
  final client = useQueryClient();
  final query = useMemoized<Query<DataType, ErrorType>>(() {
    final query = client.createQuery<DataType, ErrorType>(
      queryKey,
      queryFn,
      initial: initial,
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
    query.updateQueryFn(queryFn);
    return null;
  }, [queryFn, query]);

  useEffect(() {
    if (enabled) {
      query.fetch();
    }
    return null;
  }, [enabled]);

  useEffect(() {
    StreamSubscription<DataType>? dataSubscription;
    StreamSubscription<ErrorType>? errorSubscription;

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
