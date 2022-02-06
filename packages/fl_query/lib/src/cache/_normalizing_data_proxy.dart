import 'package:fl_query/src/core/query_key.dart';
import "package:meta/meta.dart";
import 'package:fl_query/src/cache/data_proxy.dart';

typedef DataIdResolver = String? Function(Map<String, Object?> object);

/// Implements the core (de)normalization api leveraged by the cache and proxy,
///
/// [readNormalized] and [writeNormalized] must still be supplied by the implementing class
abstract class NormalizingDataProxy extends JSONDataProxy {
  /// Flag used to request a (re)broadcast from the [QueryManager].
  ///
  /// This is set on every [writeQuery] and [writeFragment] by default.
  @protected
  @visibleForTesting
  bool broadcastRequested = false;

  /// Read normaized data from the cache
  ///
  /// Called from [readQuery] and [readFragment], which handle denormalization.
  ///
  /// The key differentiating factor for an implementing `cache` or `proxy`
  /// is usually how they handle [optimistic] reads.
  @protected
  dynamic readNormalized(String rootId, {bool? optimistic});

  /// Write normalized data into the cache.
  ///
  /// Called from [writeQuery] and [writeFragment].
  /// Implementors are expected to handle deep merging results themselves
  @protected
  void writeNormalized(String dataId, dynamic value);

  Map<String, dynamic>? readQuery(
    QueryKey queryKey, {
    bool? optimistic = true,
  }) {
    return readNormalized(queryKey.key, optimistic: optimistic);
  }

  void writeQuery(
    QueryKey queryKey, {
    required Map<String, dynamic> data,
    bool? broadcast = true,
  }) {
    writeNormalized(queryKey.key, data);
    if (broadcast ?? true) {
      broadcastRequested = true;
    }
  }
}
