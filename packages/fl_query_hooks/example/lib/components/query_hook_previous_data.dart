import 'dart:convert';

import 'package:fl_query/fl_query.dart';
import 'package:fl_query_hooks/fl_query_hooks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:http/http.dart' as http;

final todoJob = QueryJob.withVariableKey<Map, void>(
  preQueryKey: "todo",
  task: (queryKey, _) async {
    final res = await http.get(
      Uri.parse(
          "https://jsonplaceholder.typicode.com/todos/${getVariable(queryKey)}"),
    );
    return jsonDecode(res.body);
  },
  keepPreviousData: true,
);

class QueryHookPreviousDataExample extends HookWidget {
  const QueryHookPreviousDataExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final id = useState(1);
    final query =
        useQuery(job: todoJob(id.value.toString()), externalData: null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "# Query Variable Key with keepPreviousData",
          style: Theme.of(context).textTheme.headline5,
        ),
        if (query.hasError)
          Text(query.error.toString())
        else if (!query.hasData)
          const CircularProgressIndicator()
        else
          Text(jsonEncode(query.data ?? {})),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: () {
                id.value -= 1;
              },
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                id.value += 1;
              },
            ),
          ],
        )
      ],
    );
  }
}
