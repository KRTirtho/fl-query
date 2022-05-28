import 'dart:math';

import 'package:example/another_component.dart';
import 'package:fl_query/query_bowl.dart';
import 'package:fl_query/query_builder.dart';
import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const QueryBowlScope(
        staleTime: Duration(seconds: 10),
        child: MyHomePage(),
      ),
    );
  }
}

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
              QueryBuilder<String>(
                queryKey: "greetings",
                task: (queryKey) => Future.delayed(
                    const Duration(seconds: 2),
                    () =>
                        "Welcome ($queryKey) ${Random.secure().nextInt(100)}"),
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
              QueryBuilder(
                queryKey: "failure",
                task: (queryKey) =>
                    Future.value("[$queryKey] Failed for unknown reason"),
                builder: (context, query) {
                  if (query.hasError) return Text(query.error);
                  return Text("Failure. You're a failure ${query.data}");
                },
              ),
            ],
          ),
          const AnotherComponent(),
        ],
      ),
    );
  }
}
