// ignore_for_file: deprecated_member_use_from_same_package
import 'dart:async';
import 'package:fl_query/src/cache/cache.dart';
import 'package:fl_query/src/core/_base_options.dart';
import 'package:fl_query/src/core/observable_query.dart';

import 'package:fl_query/src/core/result_parser.dart';

import 'package:fl_query/src/exceptions.dart';
import 'package:fl_query/src/core/query_result.dart';
import 'package:fl_query/src/utilities/helpers.dart';
import 'package:fl_query/src/core/policies.dart';

typedef OnMutationCompleted = FutureOr<void> Function(dynamic data);
typedef OnMutationUpdate = FutureOr<void> Function(
  JSONDataProxy cache,
  QueryResult? result,
);
typedef OnError = FutureOr<void> Function(OperationException? error);

class MutationOptions<TParsed> extends BaseOptions<TParsed> {
  MutationOptions({
    required DocumentNode document,
    String? operationName,
    Map<String, dynamic> variables = const {},
    FetchPolicy? fetchPolicy,
    ErrorPolicy? errorPolicy,
    CacheRereadPolicy? cacheRereadPolicy,
    Context? context,
    Object? optimisticResult,
    this.onCompleted,
    this.update,
    this.onError,
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

  final OnMutationCompleted? onCompleted;
  final OnMutationUpdate? update;
  final OnError? onError;

  @override
  List<Object?> get properties =>
      [...super.properties, onCompleted, update, onError];
}

/// Handles execution of mutation `update`, `onCompleted`, and `onError` callbacks
class MutationCallbackHandler {
  final MutationOptions options;
  final QueryCache cache;
  final String queryId;

  MutationCallbackHandler({
    required this.options,
    required this.cache,
    required this.queryId,
  });

  // callbacks will be called against each result in the stream,
  // which should then rebroadcast queries with the appropriate optimism
  Iterable<OnData> get callbacks =>
      <OnData?>[onCompleted, update, onError].where(notNull).cast<OnData>();

  // Todo: probably move this to its own class
  OnData? get onCompleted {
    if (options.onCompleted != null) {
      return (QueryResult? result) {
        if (!result!.isLoading && !result.isOptimistic) {
          return options.onCompleted!(result.data);
        }
      };
    }
    return null;
  }

  OnData? get onError {
    if (options.onError != null) {
      return (QueryResult? result) {
        if (!result!.isLoading &&
            result.hasException &&
            options.errorPolicy != ErrorPolicy.ignore) {
          return options.onError!(result.exception);
        }
      };
    }

    return null;
  }

  /// The optimistic cache layer id `update` will write to
  /// is a "child patch" of the default optimistic patch
  /// created by the query manager
  String get _patchId => '${queryId}.update';

  /// apply the user's patch
  void _optimisticUpdate(QueryResult? result) {
    final String patchId = _patchId;
    // this is also done in query_manager, but better safe than sorry
    cache.recordOptimisticTransaction(
      (JSONDataProxy cache) {
        options.update!(cache, result);
        return cache;
      },
      patchId,
    );
  }

  // optimistic patches will be cleaned up by the query_manager
  // cleanup is handled by heirarchical optimism -
  // as in, because our patch id is prefixed with '${observableQuery.queryId}.',
  // it will be discarded along with the observableQuery.queryId patch
  // TODO this results in an implicit coupling with the patch id system
  OnData? get update {
    if (options.update != null) {
      // dereference all variables that might be needed if the widget is disposed
      final OnMutationUpdate? widgetUpdate = options.update;
      final OnData optimisticUpdate = _optimisticUpdate;

      // wrap update logic to handle optimism
      FutureOr<void> updateOnData(QueryResult? result) {
        if (result!.isOptimistic) {
          return optimisticUpdate(result);
        } else {
          return widgetUpdate!(cache, result);
        }
      }

      return updateOnData;
    }
    return null;
  }
}
