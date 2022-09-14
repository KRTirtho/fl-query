// ignore_for_file: invalid_use_of_protected_member

import 'package:fl_query/fl_query.dart';
import 'package:fl_query_hooks/src/utils.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

InfiniteQuery<T, Outside, PageParam>
    useInfiniteQuery<T extends Object, Outside, PageParam extends Object>({
  required InfiniteQueryJob<T, Outside, PageParam> job,
  required Outside externalData,

  // /// Called when the query returns new data, on query
  // /// refetch or query gets expired
  // QueryListener<T>? onData,

  // /// Called when the query returns error
  // QueryListener<dynamic>? onError,
  List<Object?>? keys,
}) {
  final context = useContext();
  final QueryBowl queryBowl = QueryBowl.of(context);
  final ValueKey<String> uKey = useMemoized(() => ValueKey(uuid.v4()), []);
  final query = useRef(
    InfiniteQuery.fromOptions(
      job,
      externalData: externalData,
      queryBowl: queryBowl,
    ),
  );

  final oldJob = usePrevious(job);
  final oldExternalData = usePrevious(externalData);
  // final oldOnData = usePrevious(onData);
  // final oldOnError = usePrevious(onError);

  final init = useCallback(([T? previousData]) {
    query.value = queryBowl.addInfiniteQuery<T, Outside, PageParam>(
      job,
      externalData: externalData,
      // previousData: previousData,
      key: uKey,
      // onData: onData,
      // onError: onError,
    );
    final hasExternalDataChanged = query.value.externalData != null &&
        query.value.prevUsedExternalData != null &&
        !isShallowEqual(
            query.value.externalData!, query.value.prevUsedExternalData!);
    if (query.value.fetched && hasExternalDataChanged) {
      query.value.refetch();
    } else if (!query.value.fetched) {
      query.value.fetch();
    }
  }, [
    queryBowl,
    query.value,
    uKey,
    job,
    externalData,
    // onData,
    // onError,
  ]);

  final disposeQuery = useCallback(() {
    query.value.unmount(uKey);
    // if (onData != null) query.value.removeDataListener(onData);
    // if (onError != null) query.value.removeErrorListener(onError);
  }, [
    query.value,
    uKey,
    // onData,
    // onError,
  ]);

  useEffect(() {
    init();
    return disposeQuery;
  }, []);

  useEffect(() {
    // final hasOnErrorChanged = oldOnError != onError && oldOnError != null;
    // final hasOnDataChanged = oldOnData != onData && oldOnData != null;
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
          // onData: onData,
          // onError: onError,
        )..refetchPages();
      } else {
        QueryBowl.of(context)
            .getQuery(job.queryKey)
            ?.setExternalData(externalData);
      }

      // if (hasOnDataChanged) query.value.removeDataListener(oldOnData);
      // if (hasOnErrorChanged) query.value.removeErrorListener(oldOnError);
    }
    // else {
    //   if (hasOnDataChanged) {
    //     query.value.removeDataListener(oldOnData);
    //     if (onData != null) query.value.addDataListener(onData);
    //   }
    //   if (hasOnErrorChanged) {
    //     query.value.removeErrorListener(oldOnError);
    //     if (onError != null) query.value.addErrorListener(onError);
    //   }
    // }
    return null;
  });

  return queryBowl.getInfiniteQuery<T, Outside, PageParam>(job.queryKey) ??
      query.value;
}
