import 'dart:convert';
import 'dart:math';

import 'package:fl_query_example/components/basic_query.dart';
import 'package:http/http.dart' as http;

import 'package:fl_query/fl_query.dart';
import 'package:flutter/material.dart';

final basicMutationJob = MutationJob<Map, Map<String, dynamic>>(
  mutationKey: "basic-mutation-example",
  task: (key, data) async {
    final response = await http.post(
      Uri.parse(
        // to simulate a failing response environment
        Random().nextBool()
            ? "https://jsonplaceholder.typicode.com/posts"
            : "https://google.com",
      ),
      headers: {'Content-type': 'application/json; charset=UTF-8'},
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  },
);

class BasicMutationExample extends StatefulWidget {
  const BasicMutationExample({Key? key}) : super(key: key);

  @override
  State<BasicMutationExample> createState() => _BasicMutationExampleState();
}

class _BasicMutationExampleState extends State<BasicMutationExample> {
  late TextEditingController titleController;
  late TextEditingController bodyController;
  late int id;
  @override
  void initState() {
    super.initState();
    id = Random().nextInt(2000000);
    titleController = TextEditingController();
    bodyController = TextEditingController();
  }

  @override
  void dispose() {
    titleController.dispose();
    bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "# Basic Mutation Example (with Failure & Retry simulation)",
          style: Theme.of(context).textTheme.headline5,
        ),
        MutationBuilder<Map, Map<String, dynamic>>(
            job: basicMutationJob,
            onMutate: (v) {
              final data =
                  QueryBowl.of(context).getQuery(successJob.queryKey)?.data;
              QueryBowl.of(context)
                  .setQueryData<String, void>(successJob.queryKey, (oldData) {
                if (oldData?.contains("After Mutate (OPTIMISTIC UPDATE)") ==
                    true) {
                  return "$oldData";
                }
                return "$oldData - After Mutate (OPTIMISTIC UPDATE)";
              });
              return data;
            },
            onData: (data, variables, context) {
              print("Passed Variable: $variables");
              print("Safe Previous Value: $context");
            },
            builder: (context, mutation) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: "Title"),
                    ),
                    TextField(
                      controller: bodyController,
                      decoration: const InputDecoration(labelText: "Body"),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        final title = titleController.value.text;
                        final body = bodyController.value.text;
                        if (body.isEmpty || title.isEmpty) return;
                        mutation.mutate({
                          "title": title,
                          "body": body,
                          "id": id,
                        }, onData: (data, variables, context) {
                          // resetting the form
                          titleController.text = "";
                          bodyController.text = "";
                        });
                      },
                      child: const Text("Post"),
                    ),
                    const SizedBox(height: 20),
                    if (mutation.hasData) Text("Response\n${mutation.data}"),
                    if (mutation.hasError) Text(mutation.error.toString()),
                  ],
                ),
              );
            }),
      ],
    );
  }
}
