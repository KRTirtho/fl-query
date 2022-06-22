import 'package:fl_query/fl_query.dart';
import 'package:flutter/material.dart';

final lazyQueryJob = QueryJob<String, String>(
    queryKey: "non_enabled_query",
    enabled: false,
    task: (queryKey, data, _) {
      return Future.delayed(const Duration(milliseconds: 500),
          () => "Hello from $queryKey with $data");
    });

class LazyQuery extends StatelessWidget {
  const LazyQuery({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: QueryBuilder<String, String>(
        job: lazyQueryJob,
        externalData: "Love",
        builder: (context, query) {
          return Column(
            children: [
              Text("Query Data::: ${query.data ?? "Loading"}"),
              ElevatedButton(
                child: const Text("Fetch Query"),
                onPressed: () => query.refetch(),
              ),
            ],
          );
        },
      ),
    );
  }
}
