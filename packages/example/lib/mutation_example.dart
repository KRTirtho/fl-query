import 'dart:convert';
import 'dart:math';

import 'package:fl_query/models/mutation_job.dart';
import 'package:fl_query/mutation_builder.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

final postSomethingJob = MutationJob<Map, Map<String, dynamic>>(
  mutationKey: "post-something-job",
  task: (key, data) async {
    final response = await http.post(
      Uri.parse(
        "https://jsonplaceholder.typicode.com/posts",
      ),
      headers: {'Content-type': 'application/json; charset=UTF-8'},
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  },
);

class MutationExample extends StatefulWidget {
  const MutationExample({Key? key}) : super(key: key);

  @override
  State<MutationExample> createState() => _MutationExampleState();
}

class _MutationExampleState extends State<MutationExample> {
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
    return Scaffold(
      appBar: AppBar(title: const Text("Post Something")),
      body: MutationBuilder<Map, Map<String, dynamic>>(
          job: postSomethingJob,
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
                      }, onData: (data) {
                        // resetting the form
                        titleController.text = "";
                        bodyController.text = "";
                      });
                    },
                    child: const Text("Post"),
                  ),
                  const SizedBox(height: 20),
                  if (mutation.hasData) Text("Response\n${mutation.data}")
                ],
              ),
            );
          }),
    );
  }
}
