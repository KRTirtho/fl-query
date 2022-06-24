import 'dart:math';

import 'package:fl_query/fl_query.dart';
import 'package:fl_query/fl_query_hooks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

final mutationHookVariableKeyJob = MutationJob.withVariableKey<String, double>(
  task: (queryKey, variables) {
    return Future.value("$variables");
  },
);

class MutationHookVariableKeyExample extends HookWidget {
  const MutationHookVariableKeyExample({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final id = useState(Random().nextDouble());
    final mutation = useMutation(
      job: mutationHookVariableKeyJob("mutation-hook-variable-key#${id.value}"),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "# Mutation  Hook Variable Key Example",
          style: Theme.of(context).textTheme.headline5,
        ),
        Row(
          children: [
            Text("${mutation.mutationKey} Result: ${mutation.data}"),
            ElevatedButton(
              child: const Text("Generate Random Data"),
              onPressed: () {
                mutation.mutate(Random().nextDouble());
              },
            ),
            ElevatedButton(
              child: const Text("New Mutation"),
              onPressed: () {
                id.value = Random().nextDouble();
              },
            ),
          ],
        ),
      ],
    );
  }
}
