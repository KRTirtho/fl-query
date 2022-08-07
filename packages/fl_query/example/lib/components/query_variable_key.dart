import 'dart:math';

import 'package:fl_query/fl_query.dart';
import 'package:flutter/material.dart';

final queryVariableKeyJob = QueryJob.withVariableKey<String, void>(
  preQueryKey: "variable-query",
  task: (queryKey, externalData) {
    return Future.delayed(
      const Duration(milliseconds: 500),
      () => "QueryKey:${queryKey.split("#").last}",
    );
  },
);

class QueryVariableKeyExample extends StatefulWidget {
  const QueryVariableKeyExample({Key? key}) : super(key: key);

  @override
  State<QueryVariableKeyExample> createState() =>
      _QueryVariableKeyExampleState();
}

class _QueryVariableKeyExampleState extends State<QueryVariableKeyExample> {
  late double id;
  @override
  void initState() {
    super.initState();
    id = Random().nextDouble() * 200;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "# Query Variable Example",
          style: Theme.of(context).textTheme.headline5,
        ),
        QueryBuilder<String, void>(
          job: queryVariableKeyJob(id.toString()),
          externalData: null,
          builder: (context, query) {
            if (query.isLoading || query.isRefetching || !query.hasData) {
              return const CircularProgressIndicator();
            }
            return Row(
              children: [
                Text("Query Result: ${query.data}"),
                ElevatedButton(
                  child: const Text("New Id"),
                  onPressed: () {
                    setState(() {
                      id = Random().nextDouble() * 200;
                    });
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
