import 'dart:math';

import 'package:fl_query/fl_query.dart';
import 'package:fl_query/fl_query_hooks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

final successHookJob = QueryJob<String, void>(
  queryKey: "greetings-hook-example",
  task: (queryKey, _) => Future.delayed(
    const Duration(seconds: 2),
    () =>
        "The work successfully executed. Data: key=($queryKey) value=${Random.secure().nextInt(100)}",
  ),
);

final canFailHookJob = QueryJob<String, void>(
  queryKey: "failure-hook-example",
  task: (queryKey, _) => Random().nextBool()
      ? Future.error("$queryKey operation failed for unknown reason")
      : Future.value(
          "Successful execution. Result: $queryKey=${Random().nextInt(100)}",
        ),
);

class BasicHookQueryExample extends HookWidget {
  const BasicHookQueryExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final successQuery = useQuery(job: successHookJob, externalData: null);
    final canFailQuery = useQuery(job: canFailHookJob, externalData: null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "# Basic Query Hook Example",
          style: Theme.of(context).textTheme.headline5,
        ),
        !successQuery.hasData ||
                successQuery.isLoading ||
                successQuery.isRefetching
            ? const CircularProgressIndicator()
            : Row(
                children: [
                  Text(successQuery.data!),
                  ElevatedButton(
                    child: const Text("Refetch"),
                    onPressed: () async {
                      await successQuery.refetch();
                    },
                  ),
                ],
              ),
        !canFailQuery.hasData ||
                canFailQuery.isLoading ||
                canFailQuery.isRefetching
            ? const CircularProgressIndicator()
            : Row(
                children: [
                  if (canFailQuery.hasError)
                    Text(
                      "${canFailQuery.error}. Retrying: ${canFailQuery.retryAttempts}",
                    ),
                  if (canFailQuery.hasData)
                    Text(
                      "Success after ${canFailQuery.retryAttempts}\nData: ${canFailQuery.data}",
                    ),
                  ElevatedButton(
                    child: const Text("Refetch"),
                    onPressed: () async {
                      await canFailQuery.refetch();
                    },
                  ),
                ],
              )
      ],
    );
  }
}
