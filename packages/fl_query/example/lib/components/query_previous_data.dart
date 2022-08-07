import 'dart:convert';

import 'package:fl_query/fl_query.dart';
import 'package:flutter/material.dart';
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

class QueryPreviousDataExample extends StatefulWidget {
  const QueryPreviousDataExample({Key? key}) : super(key: key);

  @override
  State<QueryPreviousDataExample> createState() =>
      _QueryPreviousDataExampleState();
}

class _QueryPreviousDataExampleState extends State<QueryPreviousDataExample> {
  int id = 1;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "# Query Variable Key with keepPreviousData",
          style: Theme.of(context).textTheme.headline5,
        ),
        QueryBuilder(
            job: todoJob(id.toString()),
            externalData: null,
            builder: (context, query) {
              if (query.hasError) return Text(query.error.toString());
              if (!query.hasData) return const CircularProgressIndicator();
              return Text(jsonEncode(query.data ?? {}));
            }),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: () {
                setState(() {
                  id -= 1;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                setState(() {
                  id += 1;
                });
              },
            ),
          ],
        )
      ],
    );
  }
}
