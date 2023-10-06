---
sidebar_position: 1
---

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