import 'dart:math';

import 'package:example/another_component.dart';
import 'package:example/lazy_query.dart';
import 'package:example/query_with_external_data.dart';
import 'package:fl_query/fl_query.dart';
import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return QueryBowlScope(
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          useMaterial3: true,
          primarySwatch: Colors.blue,
        ),
        home: const MyHomePage(),
      ),
    );
  }
}

final successJob = QueryJob<String, void>(
    queryKey: "greetings",
    task: (queryKey, _) => Future.delayed(const Duration(seconds: 2),
        () => "Welcome ($queryKey) ${Random.secure().nextInt(100)}"));

final failedJob = QueryJob<String, void>(
  queryKey: "failure",
  task: (queryKey, _) => Random().nextBool()
      ? Future.error("[$queryKey] Failed for unknown reason")
      : Future.value("Success, you'll get slowly ${Random().nextInt(100)}!"),
);

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fl Query Example"),
      ),
      body: Column(
        children: [
          Row(
            children: [
              QueryBuilder<String, void>(
                job: successJob,
                externalData: null,
                builder: (context, query) {
                  if (query.isLoading || query.isRefetching) {
                    return const CircularProgressIndicator();
                  }
                  return TextButton(
                    child: Text(query.data!),
                    onPressed: () async {
                      await query.refetch();
                    },
                  );
                },
              ),
              QueryBuilder<String, void>(
                job: successJob,
                externalData: null,
                builder: (context, query) {
                  if (query.isLoading || query.isRefetching) {
                    return const CircularProgressIndicator();
                  }
                  return ElevatedButton(
                    child: Text(query.data!),
                    onPressed: () async {
                      await query.refetch();
                    },
                  );
                },
              ),
              QueryBuilder<String, void>(
                job: failedJob,
                externalData: null,
                builder: (context, query) {
                  return Row(
                    children: [
                      if (query.hasError)
                        Text(
                            "${query.error}. Retrying: ${query.retryAttempts}"),
                      if (query.hasData)
                        Text(
                            "Success after ${query.retryAttempts}. Data: ${query.data}"),
                      ElevatedButton(
                        child: Text("Refetch ${query.queryKey}"),
                        onPressed: () => query.refetch(),
                      )
                    ],
                  );
                },
              ),
            ],
          ),
          ElevatedButton(
            child: const Text("External Data Example"),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const QueryWithExternalData(),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            child: const Text("Non Enabled Query Example"),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const LazyQuery(),
                ),
              );
            },
          ),
          const AnotherComponent(),
        ],
      ),
    );
  }
}
