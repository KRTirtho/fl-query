---
title: QueryBowl Scope
sidebar_position: 1
---

The first thing needed for storing any form of data is a store. QueryBowlScope is basically a `InheritedWidget` which wraps around the actual store `QueryBowl`. It is similar to `ProviderScope` in riverpod & `MultiProvider` provider. It just inject the instance of `QueryBowl` to the `BuildContext`

You must use wrap your `MaterialApp`  or `CupertinoApp` or `FluentApp` or `MacosApp` with `QueryBowlScope` for using same `QueryBowl` across all screens/routes

Or, if you want you can use `QueryBowlScope` anywhere in the Widget Tree to provide the `QueryBowl` instance to the children.

```dart
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return QueryBowlScope(
      bowl: QueryBowl(),
      child: MaterialApp(
        title: 'Fl-Query Example',
        home: const MyHomePage(),
      ),
    );
  }
}

```

`QueryBowl` has many properties that can be configured. You can configure refetch behaviors, thresholds, delays etc along with cache time

Here I'm increasing the staleTime to 10 seconds. This means that if the data is outdated after 10 seconds & will be refetched in the background smartly when needed. The default value is 1 seconds

```dart
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return QueryBowlScope(
      bowl: QueryBowl(
        staleTime: Duration(seconds: 10),
      ),
      child: MaterialApp(
        title: 'Fl-Query Example',
        home: const MyHomePage(),
      ),
    );
  }
}
```

For more information on how to use QueryBowlScope, please refer to the [QueryBowlScope](https://pub.dev/documentation/fl_query/latest/fl_query/QueryBowlScope-class.html) API Reference