import 'package:fl_query/models/mutation_job.dart';
import 'package:fl_query/mutation.dart';
import 'package:fl_query/query_bowl.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      queryBowl = QueryBowl.of(context);
      queryBowl.addMutation<T, V>(
        widget.job,
        onData: widget.onData,
        onError: widget.onError,
        onMutate: widget.onMutate,
        mount: widget,
      );
    });
  }

  @override
  void dispose() {
    final mutation = queryBowl.getMutation(widget.job.mutationKey);
    mutation?.unmount(widget);
    if (widget.onData != null) mutation?.onDataListeners.remove(widget.onData);
    if (widget.onError != null)
      mutation?.onErrorListeners.remove(widget.onError);
    if (widget.onMutate != null)
      mutation?.onMutateListeners.remove(widget.onMutate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    queryBowl = QueryBowl.of(context);
    final mutation = queryBowl.getMutation<T, V>(widget.job.mutationKey);
    if (mutation == null) return Container();
    return widget.builder(context, mutation);
  }
}
