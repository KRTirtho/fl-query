---
sidebar_position: 3
title: Quick Start
---


This is a simple & dummy example that covers the usage of 
- [Query](/)
- [QueryJob](/)

```dart
import 'package:fl_query/fl_query.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

// A QueryJob is where the Logic of how the data should be 
// fetched can defined. The task callback is a PURE Function 
// & have access to external resources through the second 
// parameter where the first parameter is the queryKey
final successJob = QueryJob<String, void>(
  queryKey: "query-example",
  task: (queryKey, externalData) => Future.delayed(
    const Duration(seconds: 2),
    () =>
        "The work successfully executed. Data: key=($queryKey) value=${
          Random.secure().nextInt(100)
        }",
  ),
);

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // QueryBowlScope creates a Bowl (metaphor for Collection/Store)
    // for all the Queries & Mutations
    return QueryBowlScope(
      child: MaterialApp(
        title: 'Fl-Query Quick Start',
        theme: ThemeData(
          useMaterial3: true,
          primarySwatch: Colors.blue,
        ),
        home: const MyHomePage(),
      ),
    );
  }
}

class BasicExample extends StatelessWidget {
  const BasicExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "# Basic Query Example",
          style: Theme.of(context).textTheme.headline5,
        ),
        // QueryBuilder Widget provides the expected query 
        // instances through the builder callback based on 
        // the passed job & externalData argument
        QueryBuilder<String, void>(
          job: successJob,
          externalData: null,
          builder: (context, query) {
            if (!query.hasData || query.isLoading || query.isRefetching) {
              return const CircularProgressIndicator();
            }
            return Row(
              children: [
                Text(query.data!),
                ElevatedButton(
                  child: const Text("Refetch"),
                  onPressed: () async {
                    await query.refetch();
                  },
                ), // Text
              ],
            ); // Row
          },
        ), // QueryBuilder
      ],
    );
  }
}
```

:::tip
If you want to explore more you can see the [Example Application](https://github.com/KRTirtho/fl-query/tree/main/packages/example) which covers a lot of use-cases

Also you can browse [Spotube/fl_query_integrate](https://github.com/KRTirtho/spotube/tree/fl_query_integrate) branch of [Spotube](https://github.com/KRTirtho/spotube/) where Fl-Query is used in a real-world application experimentally
:::