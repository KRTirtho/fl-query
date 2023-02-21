import 'dart:async';

import 'package:fl_query/fl_query.dart';
import 'package:flutter/material.dart';
import 'package:fl_query/src/widgets/state_notifier_listenable.dart';

typedef QueryListenableBuilder<DataType, ErrorType, KeyType> = Widget Function(
  BuildContext context,
  Query<DataType, ErrorType, KeyType>? query,
);

class QueryListenable<DataType, ErrorType, KeyType> extends StatefulWidget {
  final ValueKey<KeyType> queryKey;
  final QueryListenableBuilder<DataType, ErrorType, KeyType> builder;
  const QueryListenable(
    this.queryKey, {
    required this.builder,
    super.key,
  });

  @override
  State<QueryListenable<DataType, ErrorType, KeyType>> createState() =>
      _QueryListenableState<DataType, ErrorType, KeyType>();
}

class _QueryListenableState<DataType, ErrorType, KeyType>
    extends State<QueryListenable<DataType, ErrorType, KeyType>> {
  StreamSubscription<QueryCacheEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _subscription = QueryClient.of(context).cache.events.listen((event) {
        switch (event.type) {
          case QueryCacheEventType.addQuery:
          case QueryCacheEventType.removeQuery:
            if (mounted && (event.data as Query).key == widget.queryKey) {
              setState(() {});
            }
            break;
          default:
        }
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = QueryClient.of(context)
        .getQuery<DataType, ErrorType, KeyType>(widget.queryKey);

    if (query == null) {
      return widget.builder(context, null);
    }
    return StateNotifierListenable<QueryState<DataType, ErrorType>>(
      notifier: query,
      builder: (context, notifier) {
        final query = notifier as Query<DataType, ErrorType, KeyType>;
        return widget.builder(context, query);
      },
    );
  }
}
