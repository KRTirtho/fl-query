---
sidebar_position: 2
title: Installation
---

Fl-Query is just another Flutter "package" so no extra installation step needed just install it straight from https://pub.dev

```bash
$ flutter pub add fl_query
```
<br/>

### Using with `flutter_hooks`

If you're an ELITE `flutter_hooks` user or want to use `fl_query_hooks` you'll need the `flutter_hooks` & `fl_query_hooks` package

```bash
$ flutter pub add fl_query_hooks
$ flutter pub add flutter_hooks
```

The hooks can be imported as follows:

```dart
import 'package:fl_query/fl_query_hooks.dart';
```
<br/>

### Add offline support in your App (Optional)

Fl-Query supports refetching queries when internet connection is restored. To enable this feature you need to install:

```bash
$ flutter pub add fl_query_connectivity_plus_adapter
```

Add following in your `main.dart` file

```dart
import 'package:fl_query_connectivity_plus_adapter/fl_query_connectivity_plus_adapter.dart';

void main() async {
  // ....
  await QueryClient.initialize(
    connectivity: FlQueryConnectivityPlusAdapter(),
  );
  // ....
}
```
<br/>

### Try out the new devtools✨

FL-Query now offers a devtool. It is still in alpha phase but it is expected to be complete in some time

Install the devtools:

```bash
$ flutter pub add fl_query_devtools
```

Add following to `MaterialApp`'s or `CupertinoApp`'s `builder` parameter:

```dart
MaterialApp.router(
  title: 'FL Query Example',
  builder: (context, child) {
    return FlQueryDevtools(child: child!);
  },
  //...
)
```