import 'dart:math';

import 'package:fl_query/fl_query.dart';
import 'package:flutter/material.dart';

final successJob = QueryJob<String, void>(
  queryKey: "greetings-example",
  task: (queryKey, _, __) => Future.delayed(
    const Duration(seconds: 2),
    () =>
        "The work successfully executed. Data: key=($queryKey) value=${Random.secure().nextInt(100)}",
  ),
);

final canFailJob = QueryJob<String, void>(
  queryKey: "failure-example",
  task: (queryKey, _, __) => Random().nextBool()
      ? Future.error("$queryKey operation failed for unknown reason")
      : Future.value(
          "Successful execution. Result: $queryKey=${Random().nextInt(100)}",
        ),
);

class BasicQueryExample extends StatelessWidget {
  const BasicQueryExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "# Basic Query Example",
          style: Theme.of(context).textTheme.headline5,
        ),
        QueryBuilder<String, void>(
          job: successJob,
          externalData: null,
          builder: (context, query) {
            if (!query.hasData || query.isLoading || query.isRefetching) {
              return const CircularProgressIndicator();
            }
            return Row(
              children: [
                Text(query.data!),
                ElevatedButton(
                  child: const Text("Refetch"),
                  onPressed: () async {
                    await query.refetch();
                  },
                ),
              ],
            );
          },
        ),
        QueryBuilder<String, void>(
          job: canFailJob,
          externalData: null,
          builder: (context, query) {
            if (!query.hasData || query.isLoading || query.isRefetching) {
              return const CircularProgressIndicator();
            }
            return Row(
              children: [
                if (query.hasError)
                  Text(
                    "${query.error}. Retrying: ${query.retryAttempts}",
                  ),
                if (query.hasData)
                  Text(
                    "Success after ${query.retryAttempts}\nData: ${query.data}",
                  ),
                ElevatedButton(
                  child: const Text("Refetch"),
                  onPressed: () async {
                    await query.refetch();
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
