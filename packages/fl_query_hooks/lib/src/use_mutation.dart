import 'package:fl_query/fl_query.dart';
import 'package:fl_query_hooks/src/utils.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

Mutation<T, V> useMutation<T extends Object, V>({
  required MutationJob<T, V> job,

  /// Called when the query returns new data, on query
  /// refetch or query gets expired
  MutationListener<T, V>? onData,

  /// Called when the query returns error
  MutationListener<dynamic, V>? onError,

  /// called right before the mutation is about to run
  ///
  /// perfect scenario for doing optimistic updates
  MutationListenerReturnable<V, dynamic>? onMutate,
  List<Object?>? keys,
}) {
  final context = useContext();
  final mounted = useIsMounted();
  final update = useForceUpdate();
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
    update();
  }, [mutation.value, job, onData, onError, onMutate, uKey]);

  final disposeMutation = useCallback(() {
    mutation.value.unmount(uKey);
    if (onData != null) mutation.value.removeDataListener(onData);
    if (onError != null) mutation.value.removeErrorListener(onError);
    if (onMutate != null) mutation.value.removeMutateListener(onMutate);
  }, [mutation.value, onData, onError, onMutate]);

  final oldJob = usePrevious(job);
  final oldOnData = usePrevious(onData);
  final oldOnError = usePrevious(onError);
  final oldOnMutate = usePrevious(onMutate);

  useEffect(() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      init();
      QueryBowl.of(context).onMutationsUpdate<T, V>(
        (newMutation) {
          if (newMutation.mutationKey != job.mutationKey || !mounted()) return;
          mutation.value = newMutation;
          update();
        },
      );
    });
    return disposeMutation;
  }, []);

  useEffect(() {
    if (oldJob != null && oldJob.mutationKey != job.mutationKey) {
      disposeMutation();
      init();
    } else {
      if (oldOnData != onData && oldOnData != null) {
        mutation.value.removeDataListener(oldOnData);
        if (onData != null) mutation.value.addDataListener(onData);
      }
      if (oldOnError != onError && oldOnError != null) {
        mutation.value.removeErrorListener(oldOnError);
        if (onError != null) mutation.value.addErrorListener(onError);
      }
      if (oldOnMutate != onMutate && oldOnMutate != null) {
        mutation.value.removeMutateListener(oldOnMutate);
        if (onMutate != null) mutation.value.addMutateListener(onMutate);
      }
    }
    return null;
  });

  return queryBowl.getMutation(job.mutationKey) ?? mutation.value;
}
