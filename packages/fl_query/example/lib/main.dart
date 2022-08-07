import 'package:fl_query_example/components/basic_mutation.dart';
import 'package:fl_query_example/components/basic_query.dart';
import 'package:fl_query_example/components/lazy_query.dart';
import 'package:fl_query_example/components/mutation_variable_key.dart';
import 'package:fl_query_example/components/query_external_data.dart';
import 'package:fl_query_example/components/query_previous_data.dart';
import 'package:fl_query_example/components/query_variable_key.dart';
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
          children: const [
            BasicQueryExample(),
            QueryExternalDataExample(),
            LazyQueryExample(),
            QueryVariableKeyExample(),
            QueryPreviousDataExample(),
            Divider(),
            BasicMutationExample(),
            MutationVariableKeyExample(),
          ],
        ),
      )),
    );
  }
}
