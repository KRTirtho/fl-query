import 'dart:async';

import 'package:fl_query/fl_query.dart';
import 'package:fl_query_hooks/src/use_query_client.dart';
import 'package:fl_query_hooks/src/utils/use_updater.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

Query<DataType, ErrorType> useQuery<DataType, ErrorType>(
  final String queryKey,
  final QueryFn<DataType> queryFn, {
  final DataType? initial,
  final RetryConfig retryConfig = DefaultConstants.retryConfig,
  final RefreshConfig refreshConfig = DefaultConstants.refreshConfig,
  final JsonConfig<DataType>? jsonConfig,
  final ValueChanged<DataType>? onData,
  final ValueChanged<ErrorType>? onError,

  // hook specific
  final bool enabled = true,
}) {
  assert(
    (jsonConfig != null && enabled) || jsonConfig == null,
    'jsonConfig is only supported when enabled is true',
  );

  final client = useQueryClient();
  final update = useUpdater();

  final query = useMemoized(
    () => client.createQuery<DataType, ErrorType>(
      queryKey,
      queryFn,
      initial: initial,
      retryConfig: retryConfig,
      refreshConfig: refreshConfig,
      jsonConfig: jsonConfig,
    ),
    [queryKey],
  );

  final oldQueryFn = usePrevious(queryFn);
  final oldOnData = usePrevious(onData);
  final oldOnError = usePrevious(onError);

  useEffect(() {
    final removeListener = query.addListener(update);
    if (enabled) {
      query.fetch();
    }
    return removeListener;
  }, [query, enabled]);

  useEffect(() {
    StreamSubscription? dataSubscription;
    StreamSubscription? errorSubscription;
    if (onData != null || oldOnData != onData || query.key != queryKey) {
      dataSubscription = query.dataStream.listen(onData);
    }
    if (onError != null || oldOnError != onError || query.key != queryKey) {
      errorSubscription = query.errorStream.listen(onError);
    }
    return () {
      dataSubscription?.cancel();
      errorSubscription?.cancel();
    };
  }, [onData, onError, query]);

  useEffect(() {
    if (oldQueryFn != queryFn && queryKey == query.key) {
      query.updateQueryFn(queryFn);
    }
    return null;
  }, [queryFn, oldQueryFn]);

  return query;
}
