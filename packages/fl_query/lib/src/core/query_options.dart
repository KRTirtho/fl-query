// ignore_for_file: deprecated_member_use_from_same_package
import 'package:fl_query/src/core/_base_options.dart';
import 'package:fl_query/src/core/result_parser.dart';
import 'package:fl_query/src/utilities/helpers.dart';

import 'package:fl_query/fl_query.dart';

/// Query options.
class QueryOptions<TParsed> extends BaseOptions<TParsed> {
  QueryOptions({
    required DocumentNode document,
    String? operationName,
    Map<String, dynamic> variables = const {},
    FetchPolicy? fetchPolicy,
    ErrorPolicy? errorPolicy,
    CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    this.pollInterval,
    Context? context,
    ResultParserFn<TParsed>? parserFn,
  }) : super(
          fetchPolicy: fetchPolicy,
          errorPolicy: errorPolicy,
          cacheRereadPolicy: cacheRereadPolicy,
          document: document,
          operationName: operationName,
          variables: variables,
          context: context,
          optimisticResult: optimisticResult,
          parserFn: parserFn,
        );

  /// The time interval on which this query should be re-fetched from the server.
  Duration? pollInterval;

  @override
  List<Object?> get properties => [...super.properties, pollInterval];

  WatchQueryOptions<TParsed> asWatchQueryOptions({bool fetchResults = true}) =>
      WatchQueryOptions(
        document: document,
        operationName: operationName,
        variables: variables,
        fetchPolicy: fetchPolicy,
        errorPolicy: errorPolicy,
        cacheRereadPolicy: cacheRereadPolicy,
        pollInterval: pollInterval,
        fetchResults: fetchResults,
        context: context,
        optimisticResult: optimisticResult,
        parserFn: this.parserFn,
      );
}

class SubscriptionOptions<TParsed> extends BaseOptions<TParsed> {
  SubscriptionOptions({
    required DocumentNode document,
    String? operationName,
    Map<String, dynamic> variables = const {},
    FetchPolicy? fetchPolicy,
    ErrorPolicy? errorPolicy,
    CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Context? context,
    ResultParserFn<TParsed>? parserFn,
  }) : super(
          fetchPolicy: fetchPolicy,
          errorPolicy: errorPolicy,
          cacheRereadPolicy: cacheRereadPolicy,
          document: document,
          operationName: operationName,
          variables: variables,
          context: context,
          optimisticResult: optimisticResult,
          parserFn: parserFn,
        );

  /// An optimistic first result to eagerly add to the subscription stream
  Object? optimisticResult;
}

class WatchQueryOptions<TParsed> extends QueryOptions<TParsed> {
  WatchQueryOptions({
    required DocumentNode document,
    String? operationName,
    Map<String, dynamic> variables = const {},
    FetchPolicy? fetchPolicy,
    ErrorPolicy? errorPolicy,
    CacheRereadPolicy? cacheRereadPolicy,
    Object? optimisticResult,
    Duration? pollInterval,
    this.fetchResults = false,
    this.carryForwardDataOnException = true,
    bool? eagerlyFetchResults,
    Context? context,
    ResultParserFn<TParsed>? parserFn,
  })  : eagerlyFetchResults = eagerlyFetchResults ?? fetchResults,
        super(
          document: document,
          operationName: operationName,
          variables: variables,
          fetchPolicy: fetchPolicy,
          errorPolicy: errorPolicy,
          cacheRereadPolicy: cacheRereadPolicy,
          pollInterval: pollInterval,
          context: context,
          optimisticResult: optimisticResult,
          parserFn: parserFn,
        );

  /// Whether or not to fetch results
  bool fetchResults;

  /// Whether to [fetchResults] immediately on instantiation.
  /// Defaults to [fetchResults].
  bool eagerlyFetchResults;

  /// carry forward previous data in the result of errors and no data.
  /// defaults to `true`.
  bool carryForwardDataOnException;

  @override
  List<Object?> get properties =>
      [...super.properties, fetchResults, eagerlyFetchResults];

  WatchQueryOptions<TParsed> copy() => WatchQueryOptions<TParsed>(
        document: document,
        operationName: operationName,
        variables: variables,
        fetchPolicy: fetchPolicy,
        errorPolicy: errorPolicy,
        cacheRereadPolicy: cacheRereadPolicy,
        optimisticResult: optimisticResult,
        pollInterval: pollInterval,
        fetchResults: fetchResults,
        eagerlyFetchResults: eagerlyFetchResults,
        carryForwardDataOnException: carryForwardDataOnException,
        context: context,
        parserFn: parserFn,
      );
}

/// options for fetchMore operations
///
/// **NOTE**: with the addition of strict data structure checking in v4,
/// it is easy to make mistakes in writing [updateQuery].
///
/// To mitigate this, [FetchMoreOptions.partial] has been provided.
class FetchMoreOptions {
  FetchMoreOptions({
    this.document,
    this.variables = const {},
    required this.updateQuery,
  });

  /// Automatically merge the results of [updateQuery] into `previousResultData`.
  ///
  /// This is useful if you only want to, say, extract some list data
  /// from the newly fetched result, and don't want to worry about
  /// structural inconsistencies while merging.
  static FetchMoreOptions partial({
    DocumentNode? document,
    Map<String, dynamic> variables = const {},
    required UpdateQuery updateQuery,
  }) =>
      FetchMoreOptions(
        document: document,
        variables: variables,
        updateQuery: partialUpdater(updateQuery),
      );

  DocumentNode? document;

  Map<String, dynamic> variables;

  /// Strategy for merging the fetchMore result data
  /// with the result data already in the cache
  UpdateQuery updateQuery;

  /// Wrap an [UpdateQuery] in a [deeplyMergeLeft] of the `previousResultData`.
  static UpdateQuery partialUpdater(UpdateQuery update) =>
      (previous, fetched) => deeplyMergeLeft(
            [previous, update(previous, fetched)],
          );
}

/// merge fetchMore result data with earlier result data
typedef Map<String, dynamic>? UpdateQuery(
  Map<String, dynamic>? previousResultData,
  Map<String, dynamic>? fetchMoreResultData,
);
