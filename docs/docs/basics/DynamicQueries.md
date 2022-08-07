---
title: Dynamic Queries
sidebar_position: 8
---

All this time we've using queries by defining a Query Key in the `QueryJob`. But what if your widget needs to fetch data from of a dynamic id that is only known at runtime? This is where `QueryJob.withVariableKey` comes to play. It allows you to define query-key at runtime. It makes a query dynamic

```dart
final queryVariableKeyJob =
    QueryJob.withVariableKey<String, void>(
      prevQueryKey: "variable-query",
      task: (queryKey, externalData) {
      return Future.delayed(
          const Duration(milliseconds: 500),
          () => "QueryKey:${getVariable(queryKey)}",
        );
      },
);
```

Optionally, we can provide a `prevQueryKey` to make the QueryJob distinguishable from other dynamic Queries or just to keep them in a group. If you use `prevQueryKey`, you can use `getVariable` to extract the value of the variable from the `queryKey`.

:::warning
Don't use `externalData` to make a query dynamic. Using `externalData` & `refetchOnExternalDataChange: true`, you may be able to achieve similar result but it'll replace the previously fetched data with the new data instead of creating a separate `Query` instance for the new variable-query-key & it's data
:::

Now, let's use the Job with a QueryBuilder inside an actual widget:

```dart
class ExampleState extends State<Example>{
  late double id;
  @override
  void initState() {
    super.initState();
    id = Random().nextDouble() * 200;
  }

  @override
  Widget build(BuildContext context) {
    return QueryBuilder<String, void>(
      job: queryVariableKeyJob(id.toString()),
      externalData: null,
      builder: (context, query) {
        if (!query.hasData) {
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
    );
  }
}
```

Here, everything is same except to pass the `variable-query-key` to the dynamic `Query` you'll have to invoke the defined job (in this case it's `queryVariableKeyJob`) & pass the `variable-query-key` as an argument.