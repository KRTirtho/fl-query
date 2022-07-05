import 'package:fl_query/src/models/query_job.dart';
import 'package:fl_query/src/query.dart';
import 'package:fl_query/src/query_bowl.dart';
import 'package:fl_query/src/utils.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

Query<T, Outside> useQuery<T extends Object, Outside>({
  required QueryJob<T, Outside> job,
  required Outside externalData,

  /// Called when the query returns new data, on query
  /// refetch or query gets expired
  QueryListener<T>? onData,

  /// Called when the query returns error
  QueryListener<dynamic>? onError,
  List<Object?>? keys,
}) {
  final context = useContext();
  final QueryBowl queryBowl = QueryBowl.of(context);
  final ValueKey<String> uKey = useMemoized(() => ValueKey(uuid.v4()), []);
  final query = useRef(
    Query.fromOptions(
      job,
      externalData: externalData,
      queryBowl: queryBowl,
    ),
  );

  final oldJob = usePrevious(job);
  final oldExternalData = usePrevious(externalData);
  final oldOnData = usePrevious(onData);
  final oldOnError = usePrevious(onError);

  final init = useCallback(() {
    query.value = queryBowl.addQuery<T, Outside>(
      query.value,
      key: uKey,
      onData: onData,
      onError: onError,
    );
    final hasExternalDataChanged = query.value.externalData != null &&
        query.value.prevUsedExternalData != null &&
        !isShallowEqual(
            query.value.externalData!, query.value.prevUsedExternalData!);
    (query.value.fetched && query.value.refetchOnMount == true) ||
            hasExternalDataChanged
        ? query.value.refetch()
        : query.value.fetch();
  }, [queryBowl, query.value, uKey, onData, onError, job]);

  final disposeQuery = useCallback(() {
    query.value.unmount(uKey);
    if (onData != null) query.value.onDataListeners.remove(onData);
    if (onError != null) query.value.onErrorListeners.remove(onError);
  }, [query.value, onData, onError, uKey]);

  useEffect(() {
    init();
    return disposeQuery;
  }, []);

  useEffect(() {
    final hasOnErrorChanged = oldOnError != onError && oldOnError != null;
    final hasOnDataChanged = oldOnData != onData && oldOnData != null;
    if (oldJob != null && oldJob.queryKey != job.queryKey) {
      disposeQuery();
      query.value = Query.fromOptions(
        job,
        externalData: externalData,
        queryBowl: queryBowl,
      );
      init();
    } else if (oldExternalData != null &&
        externalData != null &&
        !isShallowEqual(oldExternalData, externalData)) {
      if (job.refetchOnExternalDataChange ??
          queryBowl.refetchOnExternalDataChange) {
        QueryBowl.of(context).fetchQuery(
          job,
          externalData: externalData,
          onData: onData,
          onError: onError,
          key: uKey,
        );
      } else {
        QueryBowl.of(context)
            .getQuery(job.queryKey)
            ?.setExternalData(externalData);
      }

      if (hasOnDataChanged) query.value.onDataListeners.remove(oldOnData);
      if (hasOnErrorChanged) query.value.onErrorListeners.remove(oldOnError);
    } else {
      if (hasOnDataChanged) {
        query.value.onDataListeners.remove(oldOnData);
        if (onData != null) query.value.onDataListeners.add(onData);
      }
      if (hasOnErrorChanged) {
        query.value.onErrorListeners.remove(oldOnError);
        if (onError != null) query.value.onErrorListeners.add(onError);
      }
    }
    return null;
  });

  return queryBowl.getQuery<T, Outside>(job.queryKey) ?? query.value;
}
