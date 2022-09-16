// ignore_for_file: invalid_use_of_protected_member

import 'package:fl_query/fl_query.dart';
import 'package:fl_query_hooks/src/utils.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

InfiniteQuery<T, Outside, PageParam>
    useInfiniteQuery<T extends Object, Outside, PageParam extends Object>({
  required InfiniteQueryJob<T, Outside, PageParam> job,
  required Outside externalData,

  /// Called when the query returns new data, on query
  /// refetch or query gets expired
  final InfiniteQueryListeners<T, PageParam>? onData,

  /// Called when the query returns error
  final InfiniteQueryListeners<dynamic, PageParam>? onError,
  List<Object?>? keys,
}) {
  final context = useContext();
  final QueryBowl queryBowl = QueryBowl.of(context);
  final ValueKey<String> uKey = useMemoized(() => ValueKey(uuid.v4()), []);
  final infiniteQuery = useRef(
    InfiniteQuery.fromOptions(
      job,
      externalData: externalData,
      queryBowl: queryBowl,
    ),
  );

  final oldJob = usePrevious(job);
  final oldExternalData = usePrevious(externalData);
  final oldOnData = usePrevious(onData);
  final oldOnError = usePrevious(onError);

  final init = useCallback(([T? previousData]) {
    infiniteQuery.value = queryBowl.addInfiniteQuery<T, Outside, PageParam>(
      job,
      externalData: externalData,
      key: uKey,
      onData: onData,
      onError: onError,
    );
    final hasExternalDataChanged = infiniteQuery.value.externalData != null &&
        infiniteQuery.value.prevUsedExternalData != null &&
        !isShallowEqual(infiniteQuery.value.externalData!,
            infiniteQuery.value.prevUsedExternalData!);
    if (infiniteQuery.value.fetched && hasExternalDataChanged) {
      infiniteQuery.value.refetchPages();
    } else if (!infiniteQuery.value.fetched) {
      infiniteQuery.value.fetch();
    }
  }, [
    queryBowl,
    infiniteQuery.value,
    uKey,
    job,
    externalData,
    onData,
    onError,
  ]);

  final disposeQuery = useCallback(() {
    infiniteQuery.value.unmount(uKey);
    if (onData != null) infiniteQuery.value.removeDataListener(onData);
    if (onError != null) infiniteQuery.value.removeErrorListener(onError);
  }, [
    infiniteQuery.value,
    uKey,
    onData,
    onError,
  ]);

  useEffect(() {
    init();
    return disposeQuery;
  }, []);

  useEffect(() {
    final hasOnErrorChanged = oldOnError != onError && oldOnError != null;
    final hasOnDataChanged = oldOnData != onData && oldOnData != null;
    if (oldJob != null && oldJob.queryKey != job.queryKey) {
      disposeQuery();
      init();
    } else if (oldExternalData != null &&
        externalData != null &&
        !isShallowEqual(oldExternalData, externalData)) {
      if (job.refetchOnExternalDataChange ??
          queryBowl.refetchOnExternalDataChange) {
        QueryBowl.of(context).addInfiniteQuery(
          job,
          externalData: externalData,
          key: uKey,
          onData: onData,
          onError: onError,
        )..refetchPages();
      } else {
        QueryBowl.of(context)
            .getQuery(job.queryKey)
            ?.setExternalData(externalData);
      }

      if (hasOnDataChanged) infiniteQuery.value.removeDataListener(oldOnData);
      if (hasOnErrorChanged)
        infiniteQuery.value.removeErrorListener(oldOnError);
    } else {
      if (hasOnDataChanged) {
        infiniteQuery.value.removeDataListener(oldOnData);
        if (onData != null) infiniteQuery.value.addDataListener(onData);
      }
      if (hasOnErrorChanged) {
        infiniteQuery.value.removeErrorListener(oldOnError);
        if (onError != null) infiniteQuery.value.addErrorListener(onError);
      }
    }
    return null;
  });

  return queryBowl.getInfiniteQuery<T, Outside, PageParam>(job.queryKey) ??
      infiniteQuery.value;
}
