import 'package:fl_query/src/models/mutation_job.dart';
import 'package:fl_query/src/mutation.dart';
import 'package:fl_query/src/query_bowl.dart';
import 'package:fl_query/src/utils.dart';
import 'package:flutter/widgets.dart';

class MutationBuilder<T extends Object, V> extends StatefulWidget {
  final Function(BuildContext, Mutation<T, V>) builder;
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

  const MutationBuilder({
    required this.job,
    required this.builder,
    this.onData,
    this.onError,
    this.onMutate,
    Key? key,
  }) : super(key: key);

  @override
  State<MutationBuilder<T, V>> createState() => _MutationBuilderState<T, V>();
}

class _MutationBuilderState<T extends Object, V>
    extends State<MutationBuilder<T, V>> {
  late QueryBowl queryBowl;

  late ValueKey<String> uKey;

  late Mutation<T, V> mutation;

  @override
  void initState() {
    super.initState();
    uKey = ValueKey<String>(uuid.v4());
    mutation = Mutation<T, V>.fromOptions(widget.job);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      queryBowl = QueryBowl.of(context);
      mutation = queryBowl.addMutation<T, V>(
        mutation,
        onData: widget.onData,
        onError: widget.onError,
        onMutate: widget.onMutate,
        key: uKey,
      );
    });
  }

  @override
  void didUpdateWidget(covariant MutationBuilder<T, V> oldWidget) {
    if (oldWidget.onData != widget.onData && oldWidget.onData != null) {
      mutation.onDataListeners.remove(oldWidget.onData);
      if (widget.onData != null) mutation.onDataListeners.add(widget.onData!);
    }
    if (oldWidget.onError != widget.onError && oldWidget.onError != null) {
      mutation.onErrorListeners.remove(oldWidget.onError);
      if (widget.onError != null)
        mutation.onErrorListeners.add(widget.onError!);
    }
    if (oldWidget.onMutate != widget.onMutate && oldWidget.onMutate != null) {
      mutation.onMutateListeners.remove(oldWidget.onMutate);
      if (widget.onMutate != null)
        mutation.onMutateListeners.add(widget.onMutate!);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    mutation.unmount(uKey);
    if (widget.onData != null) mutation.onDataListeners.remove(widget.onData);
    if (widget.onError != null)
      mutation.onErrorListeners.remove(widget.onError);
    if (widget.onMutate != null)
      mutation.onMutateListeners.remove(widget.onMutate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    queryBowl = QueryBowl.of(context);
    final latestMutation =
        queryBowl.getMutation<T, V>(mutation.mutationKey) ?? mutation;
    return widget.builder(context, latestMutation);
  }
}
