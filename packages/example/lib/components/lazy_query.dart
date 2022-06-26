import 'package:fl_query/fl_query.dart';
import 'package:flutter/material.dart';

final lazyQueryJob = QueryJob<String, String>(
  queryKey: "lazy-query",
  enabled: false,
  task: (
    queryKey,
    data,
  ) {
    return Future.delayed(const Duration(milliseconds: 500),
        () => "Result: key=$queryKey value=$data");
  },
);

class LazyQueryExample extends StatelessWidget {
  const LazyQueryExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "# Lazy Query Example",
          style: Theme.of(context).textTheme.headline5,
        ),
        QueryBuilder<String, String>(
          job: lazyQueryJob,
          externalData: "Love",
          builder: (context, query) {
            return Row(
              children: [
                Text("Current Data: ${query.data ?? "Loading"}"),
                ElevatedButton(
                  child: const Text("Refetch Query"),
                  onPressed: () => query.refetch(),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
