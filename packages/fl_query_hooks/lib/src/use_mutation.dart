import 'package:fl_query/fl_query.dart';
import 'package:fl_query_hooks/src/utils.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

Mutation<T, V> useMutation<T extends Object, V>({
  required MutationJob<T, V> job,

  /// Called when the query returns new data, on query
  /// refetch or query gets expired
  MutationListener<T>? onData,

  /// Called when the query returns error
  MutationListener<dynamic>? onError,

  /// called right before the mutation is about to run
  ///
  /// perfect scenario for doing optimistic updates
  MutationListener<V>? onMutate,
  List<Object?>? keys,
}) {
  final context = useContext();
  final QueryBowl queryBowl = QueryBowl.of(context);
  final ValueKey<String> uKey = useMemoized(() => ValueKey(uuid.v4()), []);
  final mutation =
      useRef(Mutation<T, V>.fromOptions(job, queryBowl: queryBowl));

  final init = useCallback(() {
    mutation.value = queryBowl.addMutation<T, V>(
      job,
      onData: onData,
      onError: onError,
      onMutate: onMutate,
      key: uKey,
    );
  }, [mutation.value, job, onData, onError, onMutate, uKey]);

  final disposeMutation = useCallback(() {
    mutation.value.unmount(uKey);
    if (onData != null) mutation.value.onDataListeners.remove(onData);
    if (onError != null) mutation.value.onErrorListeners.remove(onError);
    if (onMutate != null) mutation.value.onMutateListeners.remove(onMutate);
  }, [mutation.value, onData, onError, onMutate]);

  final oldJob = usePrevious(job);
  final oldOnData = usePrevious(onData);
  final oldOnError = usePrevious(onError);
  final oldOnMutate = usePrevious(onMutate);

  useEffect(() {
    init();
    return disposeMutation;
  }, []);

  useEffect(() {
    if (oldJob != null && oldJob.mutationKey != job.mutationKey) {
      disposeMutation();
      init();
    } else {
      if (oldOnData != onData && oldOnData != null) {
        mutation.value.onDataListeners.remove(oldOnData);
        if (onData != null) mutation.value.onDataListeners.add(onData);
      }
      if (oldOnError != onError && oldOnError != null) {
        mutation.value.onErrorListeners.remove(oldOnError);
        if (onError != null) mutation.value.onErrorListeners.add(onError);
      }
      if (oldOnMutate != onMutate && oldOnMutate != null) {
        mutation.value.onMutateListeners.remove(oldOnMutate);
        if (onMutate != null) mutation.value.onMutateListeners.add(onMutate);
      }
    }
    return null;
  });

  return queryBowl.getMutation<T, V>(job.mutationKey) ?? mutation.value;
}
