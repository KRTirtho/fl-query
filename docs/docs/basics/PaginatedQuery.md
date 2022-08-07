---
title: Paginated/Lagged Query
sidebar_position: 10
---


Rendering paginated data is a very common UI pattern and in Fl-Query, it "just works" by including the page information in the query key:

```dart
final queryVariableKeyJob = QueryJob.withVariableKey<String, void>(
      task: (queryKey, externalData) {
        return MyAPI.getData(id: getVariable(queryKey));
      },
);

/// inside a widget build method
QueryBuilder(
  job: queryVariableKeyJob(id),
  externalData: null,
  builder: (context, query){...}
)
```

However, if you run this simple example, you might notice something strange:

**The UI jumps in and out of the `success` and `loading` states because each new page is treated like a brand new query.**

This experience is not optimal and unfortunately is how many tools today insist on working. But not Fl-Query! As you may have guessed, Fl-Query comes with an awesome feature called `keepPreviousData` that allows us to get around this.

## Better Paginated Queries with `keepPreviousData`

Consider the following example where we would ideally want to increment a pageIndex (or cursor) for a query. If we were to use just `QueryJob.withVariableKey`, **it would still technically work fine**, but the UI would jump in and out of the `success` and `loading` states as different queries are created and destroyed for each page or cursor. By setting `keepPreviousData` to `true` we get a few new things:

- **The data from the last successful fetch available while new data is being requested, even though the query key has changed**.
- When the new data arrives, the previous `data` is seamlessly swapped to show the new data.
- `isPreviousData` is made available to know what data the query is currently providing you

```dart
final todoJob = QueryJob.withVariableKey<Map, void>(
  preQueryKey: "todo",
  task: (queryKey, _) async {
    final res = await http.get(
      Uri.parse(
          "https://jsonplaceholder.typicode.com/todos/${getVariable(queryKey)}"),
    );
    return jsonDecode(res.body);
  },
  keepPreviousData: true,
);

class QueryPreviousDataExample extends StatefulWidget {
  const QueryPreviousDataExample({Key? key}) : super(key: key);

  @override
  State<QueryPreviousDataExample> createState() =>
      _QueryPreviousDataExampleState();
}

class _QueryPreviousDataExampleState extends State<QueryPreviousDataExample> {
  int id = 1;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QueryBuilder(
            job: todoJob(id.toString()),
            externalData: null,
            builder: (context, query) {
              if (query.hasError) return Text(query.error.toString());
              if (!query.hasData) return const CircularProgressIndicator();
              return Text(jsonEncode(query.data ?? {}));
            }),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: () {
                setState(() {
                  id -= 1;
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                setState(() {
                  id += 1;
                });
              },
            ),
          ],
        )
      ],
    );
  }
}
```