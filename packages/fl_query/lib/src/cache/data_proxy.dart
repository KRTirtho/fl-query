import 'package:fl_query/src/core/query_key.dart';
import 'package:fl_query/src/exceptions/exceptions_next.dart';

/// The DataProxy class that can be inherited/implemented for reading
/// or writing queries in a query pool/store with queryKey
abstract class JSONDataProxy {
  /// Reads a JSON query from the root query id.
  Map<String, dynamic>? readQuery(QueryKey queryKey, {bool? optimistic});

  /// Writes (saves) a JSON data to the root query id,
  /// then [broadcast] changes to watchers unless `broadcast: false`
  ///
  /// [normalize] the given [data] into a valid JSON format. It get rids
  /// of Dart native objects
  /// Conceptually, this can be thought of as providing a manual execution result
  /// in the form of [data]
  ///
  /// For complex `normalize` type policies that involve custom reads,
  /// `optimistic` will be the default.
  ///
  /// Will throw a [PartialDataException] if the [data] structure
  /// doesn't match that of the [queryKey] `operation.document`,
  /// or a [CacheMisconfigurationException] if the write fails for some other reason.
  void writeQuery(
    QueryKey queryKey, {
    required Map<String, dynamic> data,
    bool? broadcast,
  });
}
