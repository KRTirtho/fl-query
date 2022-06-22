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
  QueryBowl queryBowl = QueryBowl.of(context);
  final ValueKey<String> uKey = useMemoized(() => ValueKey(uuid.v4()), []);
  Query<T, Outside> query = useMemoized(
      () => Query.fromOptions(
            job,
            externalData: externalData,
            queryBowl: queryBowl,
            onData: onData,
            onError: onError,
          ),
      []);

  final oldExternalData = usePrevious(externalData);
  final oldOnData = usePrevious(onData);
  final oldOnError = usePrevious(onError);

  useEffect(() {
    queryBowl.addQuery<T, Outside>(
      query,
      key: uKey,
      onData: onData,
      onError: onError,
    );
    final hasExternalDataChanged = query.externalData != null &&
        query.prevUsedExternalData != null &&
        !isShallowEqual(query.externalData!, query.prevUsedExternalData!);
    (query.fetched && query.refetchOnMount == true) || hasExternalDataChanged
        ? query.refetch()
        : query.fetch();

    return () {
      query.unmount(uKey);
      if (onData != null) query.onDataListeners.remove(onData);
      if (onError != null) query.onErrorListeners.remove(onError);
    };
  }, []);

  useEffect(() {
    if (oldExternalData != null &&
        externalData != null &&
        !isShallowEqual(oldExternalData, externalData)) {
      QueryBowl.of(context).fetchQuery(
        job,
        externalData: externalData,
        onData: onData,
        onError: onError,
        key: uKey,
      );
    } else {
      if (oldOnData != onData && oldOnData != null) {
        query.onDataListeners.remove(oldOnData);
        if (onData != null) query.onDataListeners.add(onData);
      }
      if (oldOnError != onError && oldOnError != null) {
        query.onErrorListeners.remove(oldOnError);
        if (onError != null) query.onErrorListeners.add(onError);
      }
    }
    return null;
  });

  return queryBowl.getQuery<T, Outside>(job.queryKey) ?? query;
}
