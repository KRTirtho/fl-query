import 'dart:math';

import 'package:fl_query/fl_query.dart';
import 'package:fl_query_hooks/fl_query_hooks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

final queryHookExternalDataJob = QueryJob<String, double>(
  queryKey: "query-hook-external-data",
  cacheTime: const Duration(seconds: 10),
  task: (queryKey, data) {
    return Future.delayed(const Duration(milliseconds: 500),
        () => "Hello from $queryKey with $data");
  },
);

class QueryHookExternalDataExample extends HookWidget {
  const QueryHookExternalDataExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final externalData = useState(Random().nextDouble() * 200);
    final query = useQuery(
      job: queryHookExternalDataJob,
      externalData: externalData.value,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "# Query Hook With External Data Example",
          style: Theme.of(context).textTheme.headline5,
        ),
        query.isLoading || query.isRefetching || !query.hasData
            ? const CircularProgressIndicator()
            : Row(
                children: [
                  Container(
                    width: query.externalData,
                    height: query.externalData,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue,
                    ),
                    child: Center(child: Text(query.externalData.toString())),
                  ),
                  ElevatedButton(
                    child: const Text("New Id"),
                    onPressed: () {
                      externalData.value = Random().nextDouble() * 200;
                    },
                  )
                ],
              )
      ],
    );
  }
}
