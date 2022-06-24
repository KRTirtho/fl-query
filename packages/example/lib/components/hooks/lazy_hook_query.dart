import 'package:fl_query/fl_query.dart';
import 'package:fl_query/fl_query_hooks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

final lazyHookQueryJob = QueryJob<String, String>(
  queryKey: "lazy-hook-query",
  enabled: false,
  task: (queryKey, data, _) {
    return Future.delayed(const Duration(milliseconds: 500),
        () => "Result: key=$queryKey value=$data");
  },
);

class LazyHookQueryExample extends HookWidget {
  const LazyHookQueryExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final query = useQuery(
      job: lazyHookQueryJob,
      externalData: "Love",
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "# Lazy Hook Query Example",
          style: Theme.of(context).textTheme.headline5,
        ),
        Row(
          children: [
            Text("Current Data: ${query.data ?? "Loading"}"),
            ElevatedButton(
              child: const Text("Refetch Query"),
              onPressed: () => query.refetch(),
            ),
          ],
        ),
      ],
    );
  }
}
