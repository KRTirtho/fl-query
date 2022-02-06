bool notNull(Object? any) {
  return any != null;
}

Map<String, dynamic>? _recursivelyAddAll(
  Map<String, dynamic>? target,
  Map<String, dynamic>? source,
) {
  target = Map<String, dynamic>.from(target ?? {});
  source?.forEach((String key, dynamic value) {
    if (target!.containsKey(key) &&
        target[key] is Map<String, dynamic> &&
        value != null &&
        value is Map<String, dynamic>) {
      target[key] = _recursivelyAddAll(
        target[key] as Map<String, dynamic>,
        value,
      );
    } else {
      // Lists and nulls overwrite target as if they were normal scalars
      target[key] = value;
    }
  });
  return target;
}

/// Deeply merges `maps` into a new map, merging nested maps recursively.
///
/// Paths in the rightmost maps override those in the earlier ones, so:
/// ```
/// print(deeplyMergeLeft([
///   {'keyA': 'a1'},
///   {'keyA': 'a2', 'keyB': 'b2'},
///   {'keyB': 'b3'}
/// ]));
/// // { keyA: a2, keyB: b3 }
/// ```
///
/// Conflicting [List]s are overwritten like scalars
Map<String, dynamic>? deeplyMergeLeft(
  Iterable<Map<String, dynamic>?> maps,
) {
  // prepend an empty literal for functional immutability
  return (<Map<String, dynamic>?>[{}]..addAll(maps)).reduce(_recursivelyAddAll);
}
