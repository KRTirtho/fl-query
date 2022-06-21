import 'dart:math';

import 'package:fl_query/fl_query.dart';
import 'package:flutter/material.dart';

final jobWithExternalData = QueryJob<String, String>(
    queryKey: "external_data",
    cacheTime: const Duration(seconds: 10),
    task: (queryKey, data) {
      return Future.delayed(const Duration(milliseconds: 500),
          () => "Hello from $queryKey with $data");
    });

class QueryWithExternalData extends StatelessWidget {
  const QueryWithExternalData({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: QueryBuilder<String, String>(
        job: jobWithExternalData,
        externalData: (Random().nextDouble() * 200).toString(),
        builder: (context, query) {
          if (query.isLoading || query.isRefetching || !query.hasData) {
            return const CircularProgressIndicator();
          }
          return Container(
            width: double.parse(query.externalData),
            height: double.parse(query.externalData),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue,
            ),
            child: Text(query.externalData),
          );
        },
      ),
    );
  }
}
