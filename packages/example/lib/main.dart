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
      home: const QueryBowlScope(child: MyHomePage()),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fl Query Example"),
      ),
      body: Column(
        children: [
          QueryBuilder<String>(
            queryKey: "greetings",
            task: (queryKey) => Future.value("Welcome ($queryKey)"),
            builder: (context, query) {
              if (query.isLoading) return const CircularProgressIndicator();
              return Row(
                children: [
                  TextButton(
                    child: Text(query.data!),
                    onPressed: () async {
                      await query.refetch();
                    },
                  ),
                ],
              );
            },
          )
        ],
      ),
    );
  }
}
