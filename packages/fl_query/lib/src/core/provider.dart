import 'package:fl_query/src/core/client.dart';
import 'package:flutter/material.dart';

class QueryClientProvider extends InheritedWidget {
  final QueryClient client;
  QueryClientProvider({required super.child}) : client = QueryClient();

  @override
  bool updateShouldNotify(covariant QueryClientProvider oldWidget) {
    return client != oldWidget.client;
  }
}
