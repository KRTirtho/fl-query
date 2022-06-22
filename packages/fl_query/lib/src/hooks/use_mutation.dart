import 'package:fl_query/src/models/mutation_job.dart';
import 'package:fl_query/src/mutation.dart';
import 'package:fl_query/src/query_bowl.dart';
import 'package:fl_query/src/utils.dart';
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
  return use(_UseMutation<T, V>(
    job: job,
    onData: onData,
    onError: onError,
    onMutate: onMutate,
    keys: keys,
  ));
}

class _UseMutation<T extends Object, V> extends Hook<Mutation<T, V>> {
  final MutationJob<T, V> job;

  /// Called when the query returns new data, on query
  /// refetch or query gets expired
  final MutationListener<T>? onData;

  /// Called when the query returns error
  final MutationListener<dynamic>? onError;

  /// called right before the mutation is about to run
  ///
  /// perfect scenario for doing optimistic updates
  final MutationListener<V>? onMutate;
  const _UseMutation({
    required this.job,
    this.onData,
    this.onError,
    this.onMutate,
    super.keys,
  });

  @override
  HookState<Mutation<T, V>, Hook<Mutation<T, V>>> createState() =>
      _UseMutationHookState();
}

class _UseMutationHookState<T extends Object, V>
    extends HookState<Mutation<T, V>, _UseMutation<T, V>> {
  late QueryBowl queryBowl;
  late final ValueKey<String> uKey;
  late Mutation<T, V> mutation;

  @override
  void initHook() {
    super.initHook();
    uKey = ValueKey<String>(uuid.v4());
    mutation = Mutation<T, V>.fromOptions(hook.job);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      queryBowl = QueryBowl.of(context);
      mutation = queryBowl.addMutation<T, V>(
        mutation,
        onData: hook.onData,
        onError: hook.onError,
        onMutate: hook.onMutate,
        key: uKey,
      );
    });
  }

  @override
  void didUpdateHook(_UseMutation<T, V> oldHook) {
    if (oldHook.onData != hook.onData && oldHook.onData != null) {
      mutation.onDataListeners.remove(oldHook.onData);
      if (hook.onData != null) mutation.onDataListeners.add(hook.onData!);
    }
    if (oldHook.onError != hook.onError && oldHook.onError != null) {
      mutation.onErrorListeners.remove(oldHook.onError);
      if (hook.onError != null) mutation.onErrorListeners.add(hook.onError!);
    }
    if (oldHook.onMutate != hook.onMutate && oldHook.onMutate != null) {
      mutation.onMutateListeners.remove(oldHook.onMutate);
      if (hook.onMutate != null) mutation.onMutateListeners.add(hook.onMutate!);
    }
    super.didUpdateHook(oldHook);
  }

  @override
  void dispose() {
    mutation.unmount(uKey);
    if (hook.onData != null) mutation.onDataListeners.remove(hook.onData);
    if (hook.onError != null) mutation.onErrorListeners.remove(hook.onError);
    if (hook.onMutate != null) mutation.onMutateListeners.remove(hook.onMutate);
  }

  @override
  Mutation<T, V> build(BuildContext context) {
    queryBowl = QueryBowl.of(context);
    return queryBowl.getMutation<T, V>(mutation.mutationKey) ?? mutation;
  }

  @override
  String get debugLabel => 'useQuery';
}
