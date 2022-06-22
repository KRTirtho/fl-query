import 'package:example/main.dart';
import 'package:fl_query/fl_query.dart';
import 'package:flutter/material.dart';

final dependentQueryJob = QueryJob<String, void>(
    queryKey: "dependent-query-job",
    task: (queryKey, externalData, query) {
      final successQuery =
          query.dependOnQuery<String, void>(successJob, externalData: null);
      final failedQuery =
          query.dependOnQuery<String, void>(failedJob, externalData: null);
      if (failedQuery.hasError) return failedQuery.error.toString();
      if (successQuery.hasData) return successQuery.data!;
      return "No data from success query yet";
    });

class DependentQueryExample extends StatelessWidget {
  const DependentQueryExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: QueryBuilder<String, void>(
        job: dependentQueryJob,
        externalData: null,
        builder: (context, query) {
          if (query.isLoading || query.isRefetching || !query.hasData) {
            return const CircularProgressIndicator();
          }
          return Text(query.data!);
        },
      ),
    );
  }
}
