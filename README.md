# FL-Query

Asynchronous data caching, refetching & invalidation library for Flutter. FL-Query lets you manage & distribute your async data without touching any global state

Fl-Query makes asynchronous server state management a breeze in flutter

# Features

- Async data caching & management
- Smart + effective refetching
- Optimistic updates
- Automatically cached data invalidation & unneeded query/mutation garbage collection
- Easy to write & understand code. Follows DRY (Don't repeat yourself) convention
- Compatible with both vanilla Flutter & elite [flutter_hooks](https://pub.dev/packages/flutter_hooks)

# Installation

Regular installation:

```bash
$ flutter pub add fl_query
```

For elite flutter_hooks user:

```bash
$ flutter pub add flutter_hooks
```

# Basic Usage

First wrap your `MaterialApp` with with `QueryBowlScope` widget

```dart
  Widget build(BuildContext context) {
    return QueryBowlScope(
      child: MaterialApp(
        title: 'Fl-Query Example App',
        theme: ThemeData(
          useMaterial3: true,
          primarySwatch: Colors.blue,
        ),
        home: const MyHomePage(),
      ),
    );
  }
```

Fl-Query has two types of jobs
  - `QueryJob`: Used for storing GET requests or for storing changeable yet readonly async data
  - `MutationJob`: Used for POST/PUT/DELETE requests or for mutating/changing data in services or a store asynchronously

You can write all your query or mutation logic a method parameter named `task` & identify the query uniquely by passing a unique `queryKey`

Example of a QueryJob:

```dart
final exampleQueryJob = QueryJob<Map, void>(
  queryKey: "example", // have to be unique
  task: (queryKey, externalData) async {
    final res = await http.get("/api/example-data");
    return jsonDecode(res.body);
  }
);
```

Store the `QueryJob` somewhere globally accessible in your project so you can reuse it later

Now you can use this `QueryJob` anywhere inside your flutter app inside the build method using a `QueryBuilder` widget

```dart
Widget build(BuildContext context){
  return QueryBuilder<String, void>(
      job: exampleQueryJob,
      externalData: null,
      builder: (context, query) {
        if (!query.hasData || query.isLoading) {
          return const CircularProgressIndicator();
        }
        return Row(
          children: [
            Text(query.data!),
            ElevatedButton(
              child: const Text("Refetch"),
              onPressed: () async {
                // refetches the query
                await query.refetch();
              },
            ),
          ],
        );
      },
    );
}
```

Or if you're an elite **flutter_hooks** user you can use the `useQuery` hook which is exported from the `package:fl_query/fl_query_hooks.dart` to do the same thing as above 

```dart
/* other imports */
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fl_query/fl_query_hooks.dart'; // importing the fl-query hook package

class Example extends HookWidget{
  Example(super.key);

  Widget build(BuildContext context) {
    final query = useQuery(job: exampleQueryJob, externalData: null);

    if (!query.hasData || query.isLoading) {
      return const CircularProgressIndicator();
    }
    return Row(
      children: [
        Text(query.data!),
        ElevatedButton(
          child: const Text("Refetch"),
          onPressed: () async {
            // refetches the query
            await query.refetch();
          },
        ),
      ],
    );
  }
}
```

# Why?
![The hell, why?](https://media.giphy.com/media/1M9fmo1WAFVK0/giphy.gif)

The main purpose of Fl-Query is providing the easiest way to manage the messy server-state part requiring the least amount of code with code reusability & performance

**Isn't `FutureBuilder` good?**
Yes but it is only if your commercial server has huge load of power & you're made of money or your app is simple or mostly offline & barely requires internet connection
`FutureBuilder` isn't good for data persistency & its impossible to share data across the entire application using it

**So `FutureProvider` from riverpod or provider not enough?**
Yeah, indeed its more than enough for many applications but what if your app needs Optimistic Updates & proper server-state synchronization or simply want a custom `cacheTime`? Although `FutureProvider` is a viable solution most of the `Future` related stuff, why not kick it up a notch with smart refetching capabilities with proper server-state synchronization?
Riverpod is definitely a inspiration for Fl-Query & the `QueryJob` is actually inspired by riverpod & imo is the best state management solution any library has ever provided but that's still a client state manager just like other client state manager or synchronous data manager
