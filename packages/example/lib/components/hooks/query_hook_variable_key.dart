import 'dart:math';

import 'package:fl_query/fl_query.dart';
import 'package:fl_query/fl_query_hooks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

final queryHookVariableKeyJob = QueryJob.withVariableKey<String, void>(
    task: (queryKey, externalData, query) {
  return Future.delayed(
    const Duration(milliseconds: 500),
    () => "QueryKey:${queryKey.split("#").last}",
  );
});

class QueryHookVariableKeyExample extends HookWidget {
  const QueryHookVariableKeyExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final id = useState(Random().nextDouble() * 200);
    final query = useQuery<String, void>(
      job: queryHookVariableKeyJob("hook-variable-query#${id.value}"),
      externalData: null,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "# Query Hook Variable Example",
          style: Theme.of(context).textTheme.headline5,
        ),
        query.isLoading || query.isRefetching || !query.hasData
            ? const CircularProgressIndicator()
            : Row(
                children: [
                  Text("Query Result: ${query.data}"),
                  ElevatedButton(
                    child: const Text("New Id"),
                    onPressed: () {
                      id.value = Random().nextDouble() * 200;
                    },
                  ),
                ],
              )
      ],
    );
  }
}
