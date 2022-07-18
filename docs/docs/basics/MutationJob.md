---
title: Mutation Job
sidebar_position: 5
---

`MutationJob` is just like [`QueryJob`](/docs/basics/QueryJob) but for `Mutations`.
It is used to define how & where the new data is inserted or existing data is updated or deleted. Basically, it's the kind of Job that you'll use with http `POST/PUT/DELETE` requests but it doesn't have to be just HTTP requests, it can be anything that returns as long as it returns Future

Here's a simple example:

```dart
final basicMutationJob = MutationJob<Map, Map<String, dynamic>>(
  mutationKey: "basic-mutation-example",
  task: (key, data) async {
    final response = await http.post(
      Uri.parse("https://jsonplaceholder.typicode.com/posts"),
      headers: {'Content-type': 'application/json; charset=UTF-8'},
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  },
);
```

Here, instead of a `queryKey` there's a `mutationKey` parameter that is used to identify the Job.
`Mutation` also supports _retries_ but instead of `externalData` `Mutations` has `variables` parameter that used when the `mutate` method of Mutation is called where you can pass outside data to the `Mutation.task`