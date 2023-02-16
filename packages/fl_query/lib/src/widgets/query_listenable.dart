import 'package:fl_query/fl_query.dart';
import 'package:flutter/material.dart';
import 'package:fl_query/src/widgets/state_notifier_listenable.dart';

typedef QueryListenableBuilder<DataType, ErrorType, KeyType> = Widget Function(
  BuildContext context,
  Query<DataType, ErrorType, KeyType>? query,
);

class QueryListenable<DataType, ErrorType, KeyType> extends StatelessWidget {
  final ValueKey<KeyType> queryKey;
  final QueryListenableBuilder<DataType, ErrorType, KeyType> builder;
  const QueryListenable(
    this.queryKey, {
    required this.builder,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final query = QueryClient.of(context)
        .getQuery<DataType, ErrorType, KeyType>(queryKey);

    if (query == null) {
      return builder(context, null);
    }
    return StateNotifierListenable<QueryState<DataType, ErrorType>>(
      notifier: query,
      builder: (context, notifier) {
        final query = notifier as Query<DataType, ErrorType, KeyType>;
        return builder(context, query);
      },
    );
  }
}
