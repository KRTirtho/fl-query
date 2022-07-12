---
title: QueryBowl Scope
sidebar_position: 1
---

The first thing needed for storing any form of data is a store. QueryBowlScope is basically a `StatefulWidget` which wraps around the actual store `QueryBowl`. It is similar to `ProviderScope` in riverpod & `MultiProvider` provider. But it can be used only once at the very top level of the application

You must use wrap your `MaterialApp`  or `CupertinoApp` or `FluentApp` or `MacosApp` with `QueryBowlScope`

```dart
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return QueryBowlScope(
      child: MaterialApp(
        title: 'Fl-Query Example',
        home: const MyHomePage(),
      ),
    );
  }
}

```

`QueryBowlScope` has many properties that can be configured. You can configure refetch behaviors, thresholds, delays etc along with cache time

Here I'm increasing the staleTime to 10 seconds. This means that if the data is outdated after 10 seconds & will be refetched in the background smartly when needed. The default value is 1 seconds

```dart
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return QueryBowlScope(
      staleTime: Duration(seconds: 10),
      child: MaterialApp(
        title: 'Fl-Query Example',
        home: const MyHomePage(),
      ),
    );
  }
}
```

For more information on how to use QueryBowlScope, please refer to the [QueryBowlScope](https://pub.dev/documentation/fl_query/latest/fl_query/QueryBowlScope-class.html) API Reference