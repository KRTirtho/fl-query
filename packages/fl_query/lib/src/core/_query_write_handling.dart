import 'package:fl_query/fl_query.dart';
import 'package:fl_query/src/core/query_key.dart';

/// Internal writeQuery wrapper
typedef _IntWriteQuery = void Function(
    QueryKey queryKey, Map<String, dynamic>? data);

extension InternalQueryWriteHandling on QueryManager {
  /// Merges exceptions into `queryResult` and
  /// returns `true` on success.
  ///
  /// This is named `*OrSetExceptionOnQueryResult` because it is very imperative,
  /// and edits the [queryResult] inplace.
  bool _writeQueryOrSetExceptionOnQueryResult(
    QueryKey queryKey,
    Map<String, dynamic>? data,
    QueryResult? queryResult, {
    required _IntWriteQuery writeQuery,
  }) {
    try {
      writeQuery(queryKey, data);
      return true;
    } on CacheMisconfigurationException catch (failure) {
      queryResult!.exception = coalesceErrors(
        exception: queryResult.exception,
        linkException: failure,
      );
    }
    return false;
  }

  /// Part of [InternalQueryWriteHandling], and not exposed outside the
  /// library.
  ///
  /// Returns `true` if a reread should be attempted to incorporate potential optimistic data.
  ///
  /// If we have no data, we skip caching, thus taking [ErrorPolicy.none]
  /// into account.
  ///
  /// networked wrapper for [_writeQueryOrSetExceptionOnQueryResult]
  /// NOTE: mapFetchResultToQueryResult must be called beforehand
  bool attemptCacheWriteFromResponse(
    Policies policies,
    Request request,
    Response response,
    QueryResult? queryResult,
  ) =>
      (policies.fetch == FetchPolicy.noCache || queryResult!.data == null)
          ? false
          : _writeQueryOrSetExceptionOnQueryResult(
                request,
                response.data,
                queryResult,
                writeQuery: (req, data) => cache.writeQuery(req, data: data!),
                onPartial: (failure) => UnexpectedResponseStructureException(
                  failure,
                  queryKey: request,
                  parsedResponse: response,
                ),
              ) &&
              policies.mergeOptimisticData;

  /// Part of [InternalQueryWriteHandling], and not exposed outside the
  /// library.
  ///
  /// client-side wrapper for [_writeQueryOrSetExceptionOnQueryResult]
  bool attemptCacheWriteFromClient(
    Request request,
    Map<String, dynamic>? data,
    QueryResult queryResult, {
    required _IntWriteQuery writeQuery,
  }) =>
      _writeQueryOrSetExceptionOnQueryResult(
        request,
        data,
        queryResult,
        writeQuery: writeQuery,
        onPartial: (failure) => MismatchedDataStructureException(
          failure,
          queryKey: request,
          data: data,
        ),
      );

  /// Reread the request into the result from the cache,
  /// adding a [CacheMissException] if it fails to do so
  void attempCacheRereadIntoResult(Request request, QueryResult? queryResult) {
    // normalize results if previously written
    final rereadData = cache.readQuery(request);
    if (rereadData == null) {
      queryResult!.exception = coalesceErrors(
        exception: queryResult.exception,
        linkException: CacheMissException(
          'Round trip cache re-read failed: cache.readQuery(request) returned null',
          request,
          expectedData: queryResult.data,
        ),
      );
    } else {
      queryResult!.data = rereadData;
    }
  }
}
