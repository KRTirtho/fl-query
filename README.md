!["Fl-Query Logo"](https://user-images.githubusercontent.com/61944859/178648225-611d248b-df97-4f0d-b298-b178bb141a29.png)
<h1>
  <p align="center">
    Fl-Query
  </p>
</h1>


Asynchronous data caching, refetching & invalidation library for Flutter. FL-Query lets you manage & distribute your async data without touching any global state

Fl-Query makes asynchronous server state management a breeze in flutter

# Features

- Async data caching & management
- Smart + effective refetching
- Optimistic updates
- Automatically cached data invalidation & unneeded query/mutation garbage collection
- Infinite pagination via `InfiniteQuery`
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
$ flutter pub add fl_query_hooks
```

# Docs
 
You can find the documentation (WIP) of fl-query at https://fl-query.vercel.app/

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


# Why?
<p align="center">
<img src="https://media.giphy.com/media/1M9fmo1WAFVK0/giphy.gif" alt="The hell, why?">
</p>

The main purpose of Fl-Query is providing the easiest way to manage the messy server-state part requiring the least amount of code with code reusability & performance

**Isn't `FutureBuilder` good?**
Yes but it is only if your commercial server has huge load of power & you're made of money or your app is simple or mostly offline & barely requires internet connection
`FutureBuilder` isn't good for data persistency & its impossible to share data across the entire application using it

**So `FutureProvider` from riverpod or provider not enough?**
Yeah, indeed its more than enough for many applications but what if your app needs Optimistic Updates & proper server-state synchronization or simply want a custom `cacheTime`? Although `FutureProvider` is a viable solution most of the `Future` related stuff, why not kick it up a notch with smart refetching capabilities with proper server-state synchronization?
Riverpod is definitely a inspiration for Fl-Query & the `QueryJob` is actually inspired by riverpod & imo is the best state management solution any library has ever provided but that's still a client state manager just like other client state manager or synchronous data manager


# Notice Board

This project is currently under heavy development & not yet production ready. There are lot of features to cover. If anyone encounters any unintended behavior or any bug please report it. Also we're open to improvement suggestions & feature requests

**Important!:** The project needs Dart-Flutter developers who are willing to contribute to the project by writing Tests. (I'm the worst example for tester)