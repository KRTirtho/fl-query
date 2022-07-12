---
title: Queries
sidebar_position: 3
---

### QueryBuilder

The defined logic in [QueryJob](/docs/basics/QueryJob) is bind to the Flutter UI using the `QueryBuilder` Widget. It's basically a `Builder` that takes a `QueryJob` through the `job` named parameter & creates/retrieves the appropriate `Query` and passes it down to the `builder` method

```dart
class Example extends StatelessWidget {
  const Example({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return QueryBuilder<String, void>(
      job: job,
      externalData: null,
      builder: (context, query) {
        if (!query.hasData) {
          return const CircularProgressIndicator();
        }
        return Text(query.data!);
      },
    );
  }
}
```

> Here `job` is the same `QueryJob` defined at the first snippet in the [Query Job](/docs/basics/QueryJob) tutorial

The `externalData` parameter of the `QueryBuilder` is passed to the `task` function of the `QueryJob`. It was discussed previously in [Query Job#External Data](/docs/basics/QueryJob#external-data) section

### Query
The passed query from the `builder` callback is the appropriate `Query` created based on the logic & configuration defined in the passed `QueryJob`

The `query` parameter aka `Query` contains all the useful getters, properties & methods for rendering data from the query. It contains the state of the current query, the data, the error, the loading status etc along with useful methods such as `refetch` and `setQueryData`

But more importantly, it contains the status of the current `Query`. It has to types of status one is Query Progression status & another is data availability status

You can access them as follows:
- Progressive status of Query
  - `isSuccess`: When the task function returned data successfully
  - `isError`: When the task function returned an error
  - `isLoading`: When the task function is running
  - `isRefetching`: When new data is being fetched or simply the `refetch` method is executing
  - `isIdle`: When there's no data & `Query`'s task has not been yet run
- Data availability status of Query
  - `hasData`: When query contains data (expired or not)
  - `hasError`: When the query contains error


Now the most important part of query: Data and Error. You can access the data returned from the task using `query.data` or the error `query.error`. Both the data can be null. So always check if the data/error is null before accessing it

:::info
Don't use only `query.isLoading` to check if the data is available or not as the query can be failed & at this time `data` which can cause UI Exceptions. So use `query.hasData` always to check if `data` is available yet or not or use both together
:::

Another important part of this is `refetch`. Well, you can use it to manually trigger refetch or want the query to get newest data

Finally, you can use `setQueryData` to manually set the data of the query. This is useful when you want to refresh the query but the newest data is already available in the application. It can be used to reduce network traffic by saving network calls to the server. Or you can use it with `Mutations` to optimistically set data before the Mutation is executed & then update the query with actual data

:::tip
You can learn more about Optimistic Updates in the [Mutation Tutorial](/docs/basics/mutations)
:::

Here's an real-world example of `Query` & `QueryBuilder`


```dart
final anotherJob = QueryJob<String, Client>(
  queryKey: "another-unique-key",
  task: (queryKey, httpClient){
    return httpClient
    .get("https://jsonplaceholder.typicode.com/todos/1")
    .then((response) => response.body);;
  }
);

class Example extends StatelessWidget {
  const Example({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // getting the instance of Client provided by the [provider] package
    final client = Provider.of<Client>(context);
    
    return QueryBuilder<String, void>(
      job: job,
      // passing the client as externalData
      externalData: client,
      builder: (context, query) {
        // checking if data availability along with progressive status
        if (!query.hasData || query.isLoading) {
          return const CircularProgressIndicator();
        }
        // remember to always show a fallback widget/screen for errors too. 
        // It keeps the user aware of status of the application their using
        // & saves their time
        else if(query.hasError && query.isError){
          return Text(
            "My disappointment is immeasurable & my day is ruined for this stupid error: $error",
          );
        }
        return Row(
          children: [
            Text(query.data["title"]),
            ElevatedButton(
              child: const Text("Refetch"),
              onPressed: () async {
                await query.refetch();
              },
            ),
          ],
        );
      },
    );
  }
}
```