---
sidebar_position: 1
---

### QueryClientProvider widget

The first thing needed for storing any form of data is a store. QueryClientProvider is basically a `InheritedWidget` which wraps around the actual store `QueryClient`. You must use wrap your `MaterialApp`  or `CupertinoApp` with `QueryClientProvider` for using same `QueryClient` across all screens/routes. Or, if you want you can use `QueryClientProvider` anywhere in the Widget Tree to a different `QueryClient` to the descendant widgets

```dart
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return QueryClientProvider(
      child: MaterialApp(
        title: 'Fl-Query Example',
        home: const MyHomePage(),
      ),
    );
  }
}

```

`QueryClientProvider` has many properties that can be configured. You can configure refetch behaviors, staleDuration, retries etc

Here I'm increasing the staleTime to 10 seconds. This means that if the data is outdated after 10 seconds, it will be refetched in the background smartly when needed. The default value is _2 minutes 250 milliseconds_

```dart
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return QueryClientProvider(
      child: MaterialApp(
        title: 'Fl-Query Example',
        home: const MyHomePage(),
      ),
    );
  }
}
```

> If you provide `QueryClient` to `QueryClientProvider` then assign all the parameters to `QueryClient` itself

For more information on how to use QueryClientProvider, please refer to the [QueryClientProvider](https://pub.dev/documentation/fl_query/latest/fl_query/QueryClientProvider-class.html) API Reference


## QueryClient widget

The `QueryClient` is the store that holds all the query/mutation data. You can create a new instances of `QueryClient` by calling `QueryClient()` constructor. But it is recommended to use `QueryClientProvider` to create a new instance of `QueryClient` and use it across the app.
`QueryClient` can be accessed from anywhere in the widget tree using `QueryClient.of(context)`. It can be useful for imperative data manipulation

Often there are cases where imperative access to the API is necessary. e.g. invalidating/refreshing a query from another page after a mutation
`QueryClient` gives access to the base of this framework. SO BE CAREFUL WHILE USING IT

```dart
final queryClient = QueryClient.of(context);
```

You can create/pre-fetch a query like this:
  
```dart
await queryClient.fetchQuery(
  'todos',
  () => api.getTodos(),
);
```
> `queryClient.fetchQuery` will create and fetch a query immediately if it's not already available.
> To just create a query and not fetch it, use `queryClient.createQuery` instead

Also, you can refresh queries or queries that start with a certain prefix:

```dart
// Refresh a single query
await queryClient.refreshQuery(
  'todos', 
  exact: true // pass false if you want to refresh a query with prefix
);

// Refresh multiple queries passing multiple keys
await queryClient.refreshQueries(['todos', 'posts']);

// Refresh queries with prefix
await queryClient.refreshQueriesWithPrefix('todo/');
```

:::tip
You can also use `QueryClient` to create, get, refresh/mutate `InfiniteQuery`(s) & `Mutation`(s)
:::

## QueryCache

Uhm, actually we kinda lied. QueryClient technically holds all the data but truly `QueryCache` is the one 
that truly holds all the query and mutations. `QueryClient` is just a wrapper around `QueryCache` that provides some 
useful methods and properties. `QueryCache` can be accessed using `QueryClient`'s cache property but it doesn't have any
useful methods or properties. So, it is recommended to use `QueryClient` instead of directly accessing the `QueryCache`

Also while using `QueryClient` you don't need to worry about `QueryCache` at all. It is just for the sake of knowledge

### Deleting queries/mutations from cache

One thing noticeable is there's no way to delete query/mutation using `QueryClient`. You have to use `QueryCache` for
that part. It is the only reason ever to use QueryCache

:::warning
Accessing the `QueryCache` directly is not recommended. And altering the cache can lead to unexpected behavior and
potential crashes
:::

Here's how to delete a query/mutation from cache:

```dart
final queryClient = QueryClient.of(context);
final query = queryClient.getQuery('todos');
final mutation = queryClient.getMutation('add-todos');

queryClient.cache.removeQuery(query);
queryClient.cache.removeMutation(mutation);
```
:::warning
Deleting a query/mutation from cache can be dangerous as it can cause memory leaks, infinite re-renders and crash if the
`Query`, `InfiniteQuery` or `Mutation` is still in use and mounted
:::
