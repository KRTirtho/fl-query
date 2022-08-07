import 'dart:math';

import 'package:fl_query/fl_query.dart';
import 'package:flutter/material.dart';

final jobWithExternalData = QueryJob<String, double>(
  queryKey: "query-external-data",
  cacheTime: const Duration(seconds: 10),
  refetchOnExternalDataChange: false,
  task: (queryKey, data) {
    return Future.delayed(const Duration(milliseconds: 500),
        () => "Hello from $queryKey with $data");
  },
);

class QueryExternalDataExample extends StatefulWidget {
  const QueryExternalDataExample({Key? key}) : super(key: key);

  @override
  State<QueryExternalDataExample> createState() =>
      _QueryExternalDataExampleState();
}

class _QueryExternalDataExampleState extends State<QueryExternalDataExample> {
  late double externalData;

  @override
  void initState() {
    super.initState();
    externalData = Random().nextDouble() * 200;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "# Query With External Data Example",
          style: Theme.of(context).textTheme.headline5,
        ),
        QueryBuilder<String, double>(
          job: jobWithExternalData,
          externalData: externalData,
          builder: (context, query) {
            if (query.isLoading || query.isRefetching || !query.hasData) {
              return const CircularProgressIndicator();
            }
            return Row(
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
                    setState(() {
                      externalData = Random().nextDouble() * 200;
                    });
                  },
                )
              ],
            );
          },
        ),
      ],
    );
  }
}
