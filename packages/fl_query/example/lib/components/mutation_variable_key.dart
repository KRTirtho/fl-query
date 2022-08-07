import 'dart:math';

import 'package:fl_query/fl_query.dart';
import 'package:flutter/material.dart';

final mutationVariableKeyJob = MutationJob.withVariableKey<String, double>(
  preMutationKey: "mutation-example",
  task: (queryKey, variables) {
    return Future.value("$variables");
  },
);

class MutationVariableKeyExample extends StatefulWidget {
  const MutationVariableKeyExample({Key? key}) : super(key: key);

  @override
  State<MutationVariableKeyExample> createState() =>
      _MutationVariableKeyExampleState();
}

class _MutationVariableKeyExampleState
    extends State<MutationVariableKeyExample> {
  late double id;

  @override
  void initState() {
    super.initState();
    id = Random().nextDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "# Mutation Variable Key Example",
          style: Theme.of(context).textTheme.headline5,
        ),
        MutationBuilder<String, double>(
          job: mutationVariableKeyJob(id.toString()),
          builder: (context, mutation) {
            return Row(
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
                    setState(() {
                      id = Random().nextDouble();
                    });
                  },
                ),
              ],
            );
          },
        )
      ],
    );
  }
}
