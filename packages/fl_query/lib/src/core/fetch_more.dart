import 'dart:async';

import 'package:fl_query/fl_query.dart';

import 'package:fl_query/src/core/_query_write_handling.dart';

/// Fetch more results and then merge them with [previousResult]
/// according to [FetchMoreOptions.updateQuery]
///
/// Will add results if [ObservableQuery.queryId] is supplied,
/// and broadcast any cache changes
///
/// This is the **Internal Implementation**,
/// used by [ObservableQuery] and [GraphQLCLient.fetchMore]
Future<QueryResult<TParsed>> fetchMoreImplementation<TParsed>(
  FetchMoreOptions fetchMoreOptions, {
  required QueryOptions<TParsed> originalOptions,
  required QueryManager queryManager,
  required QueryResult<TParsed> previousResult,
  String? queryId,
}) async {
  // fetch more and update

  final document = (fetchMoreOptions.document ?? originalOptions.document);
  final request = originalOptions.asRequest;

  final combinedOptions = QueryOptions<TParsed>(
    fetchPolicy: FetchPolicy.noCache,
    errorPolicy: originalOptions.errorPolicy,
    document: document,
    variables: {
      ...originalOptions.variables,
      ...fetchMoreOptions.variables,
    },
  );

  QueryResult<TParsed> fetchMoreResult =
      await queryManager.query(combinedOptions);

  try {
    // combine the query with the new query, using the function provided by the user
    final data = fetchMoreOptions.updateQuery(
      previousResult.data,
      fetchMoreResult.data,
    )!;

    fetchMoreResult.data = data;

    if (originalOptions.fetchPolicy != FetchPolicy.noCache) {
      queryManager.attemptCacheWriteFromClient(
        request,
        data,
        fetchMoreResult,
        writeQuery: (req, data) => queryManager.cache.writeQuery(
          req,
          data: data!,
        ),
      );
    }

    // will add to a stream with `queryId` and rebroadcast if appropriate
    queryManager.addQueryResult(
      request,
      queryId,
      fetchMoreResult,
    );
  } catch (error) {
    if (fetchMoreResult.hasException) {
      // because the updateQuery failure might have been because of these errors,
      // we just add them to the old errors
      previousResult.exception = coalesceErrors(
        exception: previousResult.exception,
        graphqlErrors: fetchMoreResult.exception!.graphqlErrors,
        linkException: fetchMoreResult.exception!.linkException,
      );
      return previousResult;
    } else {
      // TODO merge results OperationException
      rethrow;
    }
  }

  return fetchMoreResult;
}
