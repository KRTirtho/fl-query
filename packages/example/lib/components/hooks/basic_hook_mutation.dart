import 'dart:convert';
import 'dart:math';

import 'package:example/components/hooks/basic_hook_query.dart';
import 'package:fl_query/fl_query_hooks.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:http/http.dart' as http;

import 'package:fl_query/fl_query.dart';
import 'package:flutter/material.dart';

final basicMutationHookJob = MutationJob<Map, Map<String, dynamic>>(
  mutationKey: "basic-hook-mutation-example",
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

class BasicHookMutationExample extends HookWidget {
  const BasicHookMutationExample({super.key});
  @override
  Widget build(BuildContext context) {
    final id = useMemoized(() => Random().nextInt(2000000), []);
    final titleController = useTextEditingController();
    final bodyController = useTextEditingController();
    final mutation = useMutation(
      job: basicMutationHookJob,
      onMutate: (v) {
        QueryBowl.of(context)
            .setQueryData<String, void>(successHookJob.queryKey, (oldData) {
          if (oldData?.contains("After Mutate (OPTIMISTIC UPDATE)") == true) {
            return "$oldData";
          }
          return "$oldData - After Mutate (OPTIMISTIC UPDATE)";
        });
      },
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "# Basic Mutation Hook Example",
          style: Theme.of(context).textTheme.headline5,
        ),
        Padding(
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
                  }, onData: (data) {
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
        )
      ],
    );
  }
}
