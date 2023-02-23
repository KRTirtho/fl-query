import 'dart:math';

import 'package:fl_query/fl_query.dart';
import 'package:flutter/material.dart';

class QueryPage extends StatelessWidget {
  const QueryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final value = Random().nextInt(200000);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Query'),
      ),
      floatingActionButton:
          QueryListenable<String, dynamic>('hello', builder: (context, query) {
        if (query == null) {
          return const SizedBox();
        }
        return FloatingActionButton(
          onPressed: () {
            query.refresh();
          },
          child: Text(query.data ?? 'No Data'),
        );
      }),
      body: QueryBuilder<String, dynamic>(
        'hello',
        () {
          return Future.delayed(
              const Duration(seconds: 6), () => 'Hello World! $value');
        },
        initial: 'Hello',
        jsonConfig: JsonConfig(
          fromJson: (json) => json['data'],
          toJson: (data) => {'data': data},
        ),
        onData: (value) {
          debugPrint('onData: $value');
        },
        onError: (error) {
          debugPrint('onError: $error');
        },
        builder: (context, query) {
          if (query.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (query.hasError) {
            return Center(
              child: Text(query.error.toString()),
            );
          }
          return Center(
            child: Text(query.data ?? "Unfortunately, there's no data"),
          );
        },
      ),
    );
  }
}
