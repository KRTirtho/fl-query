import 'package:fl_query/fl_query.dart';

/// Once `gql_link` has robust http and socket exception handling,
/// these should be the only exceptions we need
import 'package:meta/meta.dart';

/// A failure to find a response from the cache.
///
/// Can occur when `cacheOnly=true`, or when the [queryKey] was just written
/// to the cache with [expectedData]
@immutable
class CacheMissException implements Exception {
  CacheMissException(this.message, this.queryKey, {this.expectedData})
      : super();

  final String message;
  final QueryKey queryKey;

  /// The data just written to the cache under [queryKey], if any.
  final Map<String, dynamic>? expectedData;

  @override
  String toString() => [
        'CacheMissException($message',
        '$queryKey',
        if (expectedData != null) 'expectedData: $expectedData)'
      ].join(', ');
}

/// A failure due to a data structure mismatch between the data and the expected
/// structure based on the [queryKey] `operation` `document`.
///
/// If [validateStructure] passes, then the mismatch must be due to a cache misconfiguration,
/// [CacheMisconfigurationException].
class MismatchedDataStructureException implements Exception {
  const MismatchedDataStructureException({
    this.queryKey,
    required this.data,
  }) : super();

  final Map<String, dynamic>? data;
  final QueryKey? queryKey;

  @override
  String toString() => 'MismatchedDataStructureException('
      'queryKey: $queryKey, '
      'data: $data, '
      ')';
}

/// Failure occurring when the structure of [data]
/// does not match that of the [queryKey] `operation` `document`.
///
/// This is checked by leveraging `normalize`
@immutable
class CacheMisconfigurationException
    implements MismatchedDataStructureException {
  const CacheMisconfigurationException({
    this.queryKey,
    required this.data,
  }) : super();

  final QueryKey? queryKey;
  final Map<String, dynamic> data;

  @override
  String toString() => [
        'CacheMisconfigurationException(',
        if (queryKey != null) 'queryKey: ${queryKey}',
        'data: ${data}, ',
        ')',
      ].join('');
}

// /// Failure occurring when the structure of the [parsedResponse] `data`
// /// does not match that of the [queryKey] `operation` `document`.
// ///
// /// This is checked by leveraging `normalize`
// @immutable
// class UnexpectedResponseStructureException extends ServerException
//     implements MismatchedDataStructureException {
//   const UnexpectedResponseStructureException(
//     this.originalException, {
//     required this.queryKey,
//     required Response parsedResponse,
//   }) : super(
//             parsedResponse: parsedResponse,
//             originalException: originalException);

//   @override
//   final Request queryKey;

//   @override
//   get data => parsedResponse!.data;

//   @override
//   final PartialDataException originalException;

//   @override
//   String toString() => 'UnexpectedResponseStructureException('
//       '$originalException, '
//       'request: ${queryKey}, '
//       'parsedResponse: ${parsedResponse}, '
//       ')';
// }

// /// Exception occurring when an unhandled, non-link exception
// /// is thrown during execution
// @immutable
// class UnknownException extends LinkException {
//   String get message => 'Unhandled Client-Side Exception: $originalException';

//   /// stacktrace of the [originalException].
//   final StackTrace originalStackTrace;

//   const UnknownException(
//     dynamic originalException,
//     this.originalStackTrace,
//   ) : super(originalException);

//   @override
//   String toString() =>
//       "UnknownException($originalException, stack:\n$originalStackTrace\n)";
// }

// /// Container for both [graphqlErrors] returned from the server
// /// and any [linkException] that caused a failure.
// class OperationException implements Exception {
//   /// Any graphql errors returned from the operation
//   List<GraphQLError> graphqlErrors = [];

//   // generalize to include cache error, etc
//   /// Errors encountered during execution such as network or cache errors
//   LinkException? linkException;

//   OperationException({
//     this.linkException,
//     Iterable<GraphQLError> graphqlErrors = const [],
//   }) : this.graphqlErrors = graphqlErrors.toList();

//   void addError(GraphQLError error) => graphqlErrors.add(error);

//   @override
//   String toString() => 'OperationException('
//       'linkException: ${linkException}, '
//       'graphqlErrors: ${graphqlErrors}'
//       ')';
// }

// /// `(graphqlErrors?, exception?) => exception?`
// ///
// /// merges both optional graphqlErrors and an optional container
// /// into a single optional container
// /// NOTE: NULL returns expected
// OperationException? coalesceErrors({
//   List<GraphQLError>? graphqlErrors,
//   LinkException? linkException,
//   OperationException? exception,
// }) {
//   if (exception != null ||
//       linkException != null ||
//       (graphqlErrors != null && graphqlErrors.isNotEmpty)) {
//     return OperationException(
//       linkException: linkException ?? exception?.linkException,
//       graphqlErrors: [
//         if (graphqlErrors != null) ...graphqlErrors,
//         if (exception?.graphqlErrors != null) ...exception!.graphqlErrors
//       ],
//     );
//   }
//   return null;
// }
