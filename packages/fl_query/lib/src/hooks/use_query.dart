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
  return use(_UseQuery<T, Outside>(
    externalData: externalData,
    job: job,
    onData: onData,
    onError: onError,
    keys: keys,
  ));
}

class _UseQuery<T extends Object, Outside> extends Hook<Query<T, Outside>> {
  final QueryJob<T, Outside> job;
  final Outside externalData;

  /// Called when the query returns new data, on query
  /// refetch or query gets expired
  final QueryListener<T>? onData;

  /// Called when the query returns error
  final QueryListener<dynamic>? onError;
  const _UseQuery({
    required this.job,
    required this.externalData,
    this.onData,
    this.onError,
    super.keys,
  });

  @override
  HookState<Query<T, Outside>, Hook<Query<T, Outside>>> createState() =>
      _UseQueryHookState();
}

class _UseQueryHookState<T extends Object, Outside>
    extends HookState<Query<T, Outside>, _UseQuery<T, Outside>> {
  late QueryBowl queryBowl;
  late final ValueKey<String> uKey;
  late Query<T, Outside> query;

  @override
  void initHook() {
    super.initHook();
    uKey = ValueKey<String>(uuid.v4());
    query = Query<T, Outside>.fromOptions(
      hook.job,
      externalData: hook.externalData,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      query = QueryBowl.of(context).addQuery<T, Outside>(
        query,
        key: uKey,
        onData: hook.onData,
        onError: hook.onError,
      );
      final hasExternalDataChanged = query.externalData != null &&
          query.prevUsedExternalData != null &&
          !isShallowEqual(query.externalData!, query.prevUsedExternalData!);
      (query.fetched && query.refetchOnMount == true) || hasExternalDataChanged
          ? await query.refetch()
          : await query.fetch();
    });
  }

  @override
  void didUpdateHook(_UseQuery<T, Outside> oldHook) {
    if (oldHook.externalData != null &&
        hook.externalData != null &&
        !isShallowEqual(oldHook.externalData!, hook.externalData!)) {
      QueryBowl.of(context).fetchQuery(
        hook.job,
        externalData: hook.externalData,
        onData: hook.onData,
        onError: hook.onError,
        key: uKey,
      );
    } else {
      if (oldHook.onData != hook.onData && oldHook.onData != null) {
        query.onDataListeners.remove(oldHook.onData);
        if (hook.onData != null) query.onDataListeners.add(hook.onData!);
      }
      if (oldHook.onError != hook.onError && oldHook.onError != null) {
        query.onErrorListeners.remove(oldHook.onError);
        if (hook.onError != null) query.onErrorListeners.add(hook.onError!);
      }
    }
    super.didUpdateHook(oldHook);
  }

  @override
  void dispose() {
    query.unmount(uKey);
    if (hook.onData != null) query.onDataListeners.remove(hook.onData);
    if (hook.onError != null) query.onErrorListeners.remove(hook.onError);
  }

  @override
  Query<T, Outside> build(BuildContext context) {
    queryBowl = QueryBowl.of(context);
    return queryBowl.getQuery<T, Outside>(query.queryKey) ?? query;
  }

  @override
  String get debugLabel => 'useQuery';
}
