---
sidebar_position: 1
id: overview
---

# Overview

Asynchronous data caching, refetching & invalidation library for Flutter. FL-Query lets you manage & distribute your async data without touching any global state

Fl-Query makes asynchronous server state management a breeze in flutter

# Features

- Async data caching & management
- Smart + effective refetching
- Optimistic updates
- Automatically cached data invalidation & unneeded query/mutation garbage collection
- Infinite pagination via `InfiniteQuery`
- Lazy persistent cache (Uses [hive](https://pub.dev/packages/hive) for persisting query results to disk) (optional)
- Easy to write & understand code. Follows DRY (Don't repeat yourself) convention
- Compatible with both vanilla Flutter & elite [flutter_hooks](https://pub.dev/packages/flutter_hooks)

# Installation

Regular installation:

```bash
$ flutter pub add fl_query
```

For elite flutter_hooks user (Welcome to the flutter cool community btw😎)

```bash
$ flutter pub add flutter_hooks fl_query_hooks
```

# Docs
 
You can find the documentation of fl-query at https://fl-query.vercel.app/

# Basic Usage

Initialize the cache databases in your `main` method

> fl-query uses [hive](https://pub.dev/packages/hive) for persisting data to disk

```dart
void main()async {
  WidgetsFlutterBinding.ensureInitialized();
  await QueryClient.initialize(cachePrefix: 'fl_query_example');
  runApp(MyApp());
}
```
In `MyApp` Widget's build method wrap your `MaterialApp` with with `QueryClientProvider` widget

```dart
  Widget build(BuildContext context) {
    return QueryClientProvider(
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

Let's write use a `Query` now
FL-Query provides a `QueryBuilder` widget that creates and listens to the specified `Query`
and re-runs the builder function whenever there's an update

It has 2 required parameters `key`(unnamed) & `builder`

```dart
class MyApp extends StatelessWidget{
    MyApp({super.key});

    @override
    build(context){
      return QueryBuilder<String, dynamic>(
        'hello',
        () {
          return Future.delayed(
              const Duration(seconds: 6), () => 'Hello World!');
        },
        initial: 'A replacement',
        jsonConfig: JsonConfig(
          fromJson: (json) => json['data'],
          toJson: (data) => {'data': data},
        ),
        onData: (value) {
          debugPrint('onData: $value');
        },
        onError: (error) {
          debugPrint('onError: $error');
        },
        builder: (context, query) {
          if (query.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (query.hasError) {
            return Center(
              child: Text(query.error.toString()),
            );
          }
          return Center(
            child: Text(query.data ?? "Unfortunately, there's no data"),
          );
        },
      );
    }
}
```

And if you're using **flutter_hooks** you got that too

```dart
class MyApp extends HookWidget{
    MyApp({super.key});

    @override
    build(context){
      final query = useQuery<String, dynamic>(
        'hello',
        () {
          return Future.delayed(
              const Duration(seconds: 6), () => 'Hello World!');
        },
        initial: 'A replacement',
        jsonConfig: JsonConfig(
          fromJson: (json) => json['data'],
          toJson: (data) => {'data': data},
        ),
        onData: (value) {
          debugPrint('onData: $value');
        },
        onError: (error) {
          debugPrint('onError: $error');
        },
      );

      if (query.isLoading) {
        return const Center(
            child: CircularProgressIndicator(),
          );
      } else if (query.hasError) {
        return Center(
          child: Text(query.error.toString()),
        );
      }
      return Center(
        child: Text(query.data ?? "Unfortunately, there's no data"),
      );
    }
}
```

*To master the fl-query follow the official blog at https://fl-query.krtirtho.dev/blog*

# Why?
<p align="center">
<img src="https://media.giphy.com/media/1M9fmo1WAFVK0/giphy.gif" alt="The hell, why?"/>
</p>

The main purpose of Fl-Query is providing the easiest way to manage the messy server-state part requiring the least amount of code with code reusability & performance
This let's you focus more on those cool UI animations & transitions✨. Leave the boring stuff to fl-query

**Q. Isn't `FutureBuilder` good?**

 No, of course not. Unless you're from 2013 or your app is a purely offline app

**Q. So `FutureProvider` from riverpod or provider not enough?**

Probably yes. Although riverpod@v2 has added a lot of caching related features but still optimistic updates, periodic refetching & disk persistence are missing. Let's not forget about infinite pagination, it's a nightmare😅. In case of provider, same story. It's a great package but it's not ideal for server-state management