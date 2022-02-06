import 'package:fl_query/src/core/_data_class.dart';
import 'package:fl_query/fl_query.dart';
import 'package:fl_query/src/core/result_parser.dart';

/// TODO refactor into [Request] container
/// Base options.
abstract class BaseOptions<TParsed> extends MutableDataClass {
  BaseOptions({
    required this.document,
    this.variables = const {},
    this.operationName,
    ResultParserFn<TParsed>? parserFn,
    Context? context,
    FetchPolicy? fetchPolicy,
    ErrorPolicy? errorPolicy,
    CacheRereadPolicy? cacheRereadPolicy,
    this.optimisticResult,
  })  : policies = Policies(
          fetch: fetchPolicy,
          error: errorPolicy,
          cacheReread: cacheRereadPolicy,
        ),
        context = context ?? Context(),
        parserFn = parserFn ??
            ((d) => throw UnimplementedError(
                  "Please provide a parser function to support result parsing.",
                ));

  /// Document containing at least one [OperationDefinitionNode]
  DocumentNode document;

  /// Name of the executable definition
  ///
  /// Must be specified if [document] contains more than one [OperationDefinitionNode]
  String? operationName;

  /// A map going from variable name to variable value, where the variables are used
  /// within the GraphQL query.
  Map<String, dynamic> variables;

  /// An optimistic result to eagerly add to the operation stream
  Object? optimisticResult;

  /// Specifies the [Policies] to be used during execution.
  Policies policies;

  FetchPolicy? get fetchPolicy => policies.fetch;

  ErrorPolicy? get errorPolicy => policies.error;

  CacheRereadPolicy? get cacheRereadPolicy => policies.cacheReread;

  /// Context to be passed to link execution chain.
  Context context;

  ResultParserFn<TParsed> parserFn;

  // TODO consider inverting this relationship
  /// Resolve these options into a request
  Request get asRequest => Request(
        operation: Operation(
          document: document,
          operationName: operationName,
        ),
        variables: variables,
        context: context,
      );

  @override
  List<Object?> get properties => [
        document,
        operationName,
        variables,
        optimisticResult,
        policies,
        context,
      ];

  OperationType get type {
    final definitions =
        document.definitions.whereType<OperationDefinitionNode>().toList();
    if (operationName != null) {
      definitions.removeWhere(
        (node) => node.name!.value != operationName,
      );
    }
    // TODO differentiate error types, add exception
    assert(definitions.length == 1);
    return definitions.first.type;
  }

  bool get isQuery => type == OperationType.query;
  bool get isMutation => type == OperationType.mutation;
  bool get isSubscription => type == OperationType.subscription;
}
