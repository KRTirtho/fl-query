---
title: Lazy Query
sidebar_position: 7
---

If you ever want to disable a query from automatically running, you can use the enabled = false option in [`QueryJob`](/docs/basics/QueryJob)

When `enabled` is false:

- If the query has initial data
    - The query will be initialized in the status === 'success' or isSuccess state.
- If the query does not have any data
    - The query will start in the status === 'idle' or isIdle state.
- The query will not automatically `fetch` on mount.
- The query will not automatically `refetch` in the background when new instances mount or new instances appearing
- The query will ignore query client `invalidateQueries` and `refetchQueries` calls that would normally result in the query refetching.
- `refetch` can be used to manually trigger the query to fetch

Here's a basic QueryJob that won't run automatically:

```dart
final lazyQueryJob = QueryJob<String, String>(
  queryKey: "lazy-query",
  enabled: false,
  task: (queryKey, data) {
    return Future.delayed(const Duration(milliseconds: 500),
        () => "Result: key=$queryKey value=$data");
  },
);
```

Let's use this Lazy Query Job in our example:

```dart
  @override
  Widget build(BuildContext context) {
    return QueryBuilder<String, String>(
      // This query won't run automatically anyway unless the [refetch] method
      // is called
      job: lazyQueryJob,
      externalData: "I can get your heart beat beat beat beating like",
      builder: (context, query) {
        return Row(
          children: [
            Text("Current Data: ${query.data ?? "Loading"}"),
            ElevatedButton(
              child: const Text("Refetch Query"),
              onPressed: () => query.refetch(),
            ),
          ],
        );
      },
    );
  }
```