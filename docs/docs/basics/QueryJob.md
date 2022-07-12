---
title: Query Job
sidebar_position: 2 
---

Query Jobs are what you use to define the logic how or from where the data is fetched/queried. It is where the `task` function is defined. `QueryJob` is reusable throughout application

Here's a simple example

```dart
final job = QueryJob<String, void>(
  queryKey: "a-unique-key",
  task: (queryKey, externalData){
    return Future.delayed(Duration(seconds: 1), () => "Hello World");
  }
);
```

The `queryKey` must be unique. It is used to identify the job

The `task` callback has to be asynchronous. When the `task` is run by `Query` the `queryKey` & the `externalData` passed from `QueryBuilder` is passed to it as parameters. The externalData can be anything. You can provide a Generic Type parameter for it too

:::info
If `externalData` is of an `Iterable` type (`Map`, `List`, `Set` etc), it will be compared [shallowly](https://medium.com/nerdjacking/shallow-deep-comparison-9fd74ac0f3d2)
:::

### External Data

A more real-world example of `QueryJob` with `externalData`

```dart
import 'package:fl_query/fl_query.dart';
import 'package:http/http.dart';

final anotherJob = QueryJob<String, Client>(
  queryKey: "another-unique-key",
  task: (queryKey, httpClient){
    return httpClient.get("https://jsonplaceholder.typicode.com/todos/1").then((response) => response.body);;
  }
);
```

Here `externalData` is a configured `Client` from the `http` package.

By default when `externalData` changes or updates the query is not refetched but if you want it to refetch when the `externalData` changes, you can set `refetchOnExternalDataChange` property of `QueryJob` to `true`. If you want this behavior globally to be enabled then you can set `refetchOnExternalDataChange` property of [QueryBowlScope](/docs/basics/QueryBowlScope) to `true`


```dart
import 'package:fl_query/fl_query.dart';
import 'package:http/http.dart';

final anotherJob = QueryJob<String, Client>(
  queryKey: "another-unique-key",
  refetchOnExternalDataChange: true,
  task: (queryKey, httpClient){
    return httpClient.get("https://jsonplaceholder.typicode.com/todos/1").then((response) => response.body);;
  }
);
```

Now every time when the externalData changes the query will refetched.

### Retries

When a query returns an `Exception` or in other word, fails, the query is re-run multiple times in the background until it succeeds or the retry limit is reached. You can configure the retry behavior of query by modifying `retries` & `retryDelay` properties of `QueryJob`

- `retries`: is amount of times the query will be retried before setting the status as `QueryStatus.error`. If its zero, it will not retry.

- `retryDelay`: is the `Duration` between retries. That means after what amount of duration the retries will take place until it succeeds or the retry limit is reached.

By default `retries` is `3` and `retryDelay` is `Duration(milliseconds: 200)`


```dart
final job = QueryJob<String, Client>(
  queryKey: "exceptional-query",
  retries: 10,
  retryDelay: Duration(milliseconds: 200),
  task: (queryKey, _) async {
    throw Exception("I'm an evil Exception");
  }
);
```

Now the query will be retried 10 times with a delay of 200ms between each retry

There are more properties of `QueryJob` that you can configure. See the API reference of [QueryJob](https://pub.dev/documentation/fl_query/latest/fl_query/QueryJob-class.html)