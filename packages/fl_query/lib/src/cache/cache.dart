import 'package:collection/collection.dart' show IterableExtension;
import 'package:fl_query/src/cache/_normalizing_data_proxy.dart';
import 'package:meta/meta.dart';

import 'package:fl_query/src/utilities/helpers.dart';
import 'package:fl_query/src/cache/store.dart';

import 'package:fl_query/src/cache/_optimistic_transactions.dart';

export 'package:fl_query/src/cache/data_proxy.dart';
export 'package:fl_query/src/cache/store.dart';
export 'package:fl_query/src/cache/hive_store.dart';

typedef VariableEncoder = Object Function(Object t);

/// Optimistic JSON data cache with configurable [store].
///
/// **NOTE**: The default [InMemoryStore] does _not_ persist to disk.
/// The recommended store for persistent environments is the [HiveStore].
///
/// [dataIdFromObject] and [typePolicies] are passed down to [normalize] operations, which say:
/// > IDs are determined by the following:
/// >
/// > 1. If a `TypePolicy` is provided for the given type, it's `TypePolicy.keyFields` are used.
/// > 2. If a `dataIdFromObject` funciton is provided, the result is used.
/// > 3. The `id` or `_id` field (respectively) are used.
class QueryCache extends NormalizingDataProxy {
  QueryCache({
    Store? store,
  }) : store = store ?? InMemoryStore();

  /// Stores the underlying normalized data. Defaults to an [InMemoryStore]
  ///
  /// **WARNING**: Directly editing the contents of the store will not automatically
  /// rebroadcast operations.
  final Store store;

  /// Tracks the number of ongoing transactions (cache updates)
  /// to prevent rebroadcasts until they are completed.
  ///
  /// **NOTE**: Does not track network calls
  @protected
  int inflightOptimisticTransactions = 0;

  /// Whether a cache operation has requested a broadcast and it is safe to do.
  ///
  /// The caller must [claimExectution] to clear the [broadcastRequested] flag.
  ///
  /// This is not meant to be called outside of the [QueryManager]
  bool shouldBroadcast({bool claimExecution = false}) {
    if (inflightOptimisticTransactions == 0 && broadcastRequested) {
      if (claimExecution) {
        broadcastRequested = false;
      }
      return true;
    }
    return false;
  }

  /// List of patches recorded through [recordOptimisticTransaction]
  ///
  /// They are applied in ascending order,
  /// thus data in `last` will overwrite that in `first`
  /// if there is a conflict
  @protected
  @visibleForTesting
  List<OptimisticPatch> optimisticPatches = [];

  /// Reads dereferences an entity from the first valid optimistic layer,
  /// defaulting to the base internal HashMap.
  @override
  Object? readNormalized(String rootId, {bool? optimistic = true}) {
    Object? value = store.get(rootId);

    if (!optimistic!) {
      return value;
    }

    for (final patch in optimisticPatches) {
      if (patch.data.containsKey(rootId)) {
        final Object? patchData = patch.data[rootId];
        if (value is Map<String, Object> && patchData is Map<String, Object>) {
          value = deeplyMergeLeft([
            value,
            patchData,
          ]);
        } else {
          // Overwrite if not mergable
          value = patchData;
        }
      }
    }

    return value;
  }

  /// Write normalized data into the cache,
  /// deeply merging maps with existing values
  ///
  /// Called from [witeQuery] and [writeFragment].
  @override
  void writeNormalized(String dataId, dynamic value) {
    if (value is Map<String, Object>) {
      final existing = store.get(dataId);
      store.put(
        dataId,
        existing != null ? deeplyMergeLeft([existing, value]) : value,
      );
    } else {
      store.put(dataId, value);
    }
  }

  String? _parentPatchId(String id) {
    final List<String> parts = id.split('.');
    if (parts.length > 1) {
      return parts.first;
    }
    return null;
  }

  bool _patchExistsFor(String id) =>
      optimisticPatches.firstWhereOrNull(
        (patch) => patch.id == id,
      ) !=
      null;

  /// avoid race conditions from slow updates
  ///
  /// if a server result is returned before an optimistic update is finished,
  /// that update is discarded
  bool _safeToAdd(String id) {
    final String? parentId = _parentPatchId(id);
    return parentId == null || _patchExistsFor(parentId);
  }

  // TODO does patch hierachy still makes sense
  /// Record the given [transaction] into a patch with the id [addId]
  ///
  /// 1 level of hierarchical optimism is supported:
  /// * if a patch has the id `$queryId.child`, it will be removed with `$queryId`
  /// * if the update somehow fails to complete before the root response is removed,
  ///   It will still be called, but the result will not be added.
  ///
  /// This allows for multiple optimistic treatments of a query,
  /// without having to tightly couple optimistic changes
  void recordOptimisticTransaction(
    CacheTransaction transaction,
    String addId,
  ) {
    inflightOptimisticTransactions += 1;
    final _proxy = transaction(OptimisticProxy(this)) as OptimisticProxy;
    if (_safeToAdd(addId)) {
      optimisticPatches.add(_proxy.asPatch(addId));
      broadcastRequested = broadcastRequested || _proxy.broadcastRequested;
    }
    inflightOptimisticTransactions -= 1;
  }

  /// Remove a given patch from the list
  ///
  /// This will also remove all "nested" patches, such as `$queryId.update`
  /// (see [recordOptimisticTransaction])
  ///
  /// This allows for hierarchical optimism that is automatically cleaned up
  /// without having to tightly couple optimistic changes
  void removeOptimisticPatch(String removeId) {
    optimisticPatches.removeWhere(
      (patch) => patch.id == removeId || _parentPatchId(patch.id) == removeId,
    );
    broadcastRequested = true;
  }
}
