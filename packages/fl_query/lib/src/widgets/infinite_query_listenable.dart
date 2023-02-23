import 'dart:async';

import 'package:fl_query/fl_query.dart';
import 'package:flutter/material.dart';
import 'package:fl_query/src/widgets/state_notifier_listenable.dart';

typedef InfiniteQueryListenableBuilder<DataType, ErrorType, PageType> = Widget
    Function(
  BuildContext context,
  InfiniteQuery<DataType, ErrorType, PageType>? query,
);

class InfiniteQueryListenable<DataType, ErrorType, PageType>
    extends StatefulWidget {
  final String queryKey;
  final InfiniteQueryListenableBuilder<DataType, ErrorType, PageType> builder;
  const InfiniteQueryListenable(
    this.queryKey, {
    required this.builder,
    super.key,
  });

  @override
  State<InfiniteQueryListenable<DataType, ErrorType, PageType>> createState() =>
      _InfiniteQueryListenableState<DataType, ErrorType, PageType>();
}

class _InfiniteQueryListenableState<DataType, ErrorType, PageType>
    extends State<InfiniteQueryListenable<DataType, ErrorType, PageType>> {
  StreamSubscription<QueryCacheEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _subscription = QueryClient.of(context).cache.events.listen((event) {
        switch (event.type) {
          case QueryCacheEventType.addInfiniteQuery:
          case QueryCacheEventType.removeInfiniteQuery:
            if (mounted &&
                (event.data as InfiniteQuery).key == widget.queryKey) {
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
        .getInfiniteQuery<DataType, ErrorType, PageType>(widget.queryKey);

    if (query == null) {
      return widget.builder(context, null);
    }
    return StateNotifierListenable<
        InfiniteQueryState<DataType, ErrorType, PageType>>(
      notifier: query,
      builder: (context, notifier) {
        final query = notifier as InfiniteQuery<DataType, ErrorType, PageType>;
        return widget.builder(context, query);
      },
    );
  }
}
