import 'dart:math';

import 'package:example/components/basic_mutation.dart';
import 'package:example/components/basic_query.dart';
import 'package:example/components/hooks/basic_hook_mutation.dart';
import 'package:example/components/hooks/basic_hook_query.dart';
import 'package:example/components/hooks/lazy_hook_query.dart';
import 'package:example/components/hooks/mutation_hook_variable_key.dart';
import 'package:example/components/hooks/query_hook_external_data.dart';
import 'package:example/components/hooks/query_hook_variable_key.dart';
import 'package:example/components/lazy_query.dart';
import 'package:example/components/mutation_variable_key.dart';
import 'package:example/components/query_external_data.dart';
import 'package:example/components/query_variable_key.dart';
import 'package:fl_query/fl_query.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return QueryBowlScope(
      child: MaterialApp(
        // showPerformanceOverlay: true,
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

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fl Query Example"),
      ),
      body: SingleChildScrollView(
          child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Regular Flutter Examples
            const BasicQueryExample(),
            const QueryExternalDataExample(),
            const LazyQueryExample(),
            const QueryVariableKeyExample(),
            const Divider(),
            const BasicMutationExample(),
            const MutationVariableKeyExample(),

            const Divider(color: Colors.amber, thickness: 5),
            Align(
              alignment: Alignment.topLeft,
              child: Text(
                "!Warning! Cool people only...\nFlutter Hooks Example",
                style: Theme.of(context).textTheme.headline3,
              ),
            ),
            const Divider(color: Colors.amber, thickness: 5),
            // elite flutter_hooks examples for only elite flutter
            // developers
            const BasicHookQueryExample(),
            const QueryHookExternalDataExample(),
            const LazyHookQueryExample(),
            const QueryHookVariableKeyExample(),
            const Divider(),
            const BasicHookMutationExample(),
            const MutationHookVariableKeyExample(),
          ],
        ),
      )),
    );
  }
}
