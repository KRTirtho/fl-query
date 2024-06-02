import 'dart:math';

import 'package:fl_query/fl_query.dart';
import 'package:fl_query_hooks/fl_query_hooks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class QueryPage extends HookWidget {
  const QueryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final value = Random().nextInt(200000);
    final query = useQuery<String, dynamic>(
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
    );

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
      body: query.isFetching
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : query.hasError
              ? Center(
                  child: Text(query.error.toString()),
                )
              : Center(
                  child: Text(query.data ?? "Unfortunately, there's no data"),
                ),
    );
  }
}
