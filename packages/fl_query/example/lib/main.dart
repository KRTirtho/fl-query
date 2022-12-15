import 'package:fl_query_example/components/basic_infinite_query.dart';
import 'package:fl_query_example/components/basic_mutation.dart';
import 'package:fl_query/fl_query.dart';
import 'package:fl_query_example/components/basic_query.dart';
import 'package:fl_query_example/components/infinite_query_disk_cache.dart';
import 'package:fl_query_example/components/lazy_query.dart';
import 'package:fl_query_example/components/mutation_variable_key.dart';
import 'package:fl_query_example/components/query_disk_cache.dart';
import 'package:fl_query_example/components/query_external_data.dart';
import 'package:fl_query_example/components/query_previous_data.dart';
import 'package:fl_query_example/components/query_variable_key.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFlQuery(cacheKey: "example");
  debugRepaintRainbowEnabled = true;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return QueryBowlScope(
      bowl: QueryBowl(),
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
            const BasicQueryExample(),
            const QueryExternalDataExample(),
            const LazyQueryExample(),
            const QueryVariableKeyExample(),
            const QueryPreviousDataExample(),
            ListTile(
              title: const Text("Infinite Query Example"),
              trailing: const Icon(Icons.open_in_new),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const BasicInfiniteQueryExample(),
                  ),
                );
              },
            ),
            const QueryDiskCacheExample(),
            const InfiniteQueryDiskCacheExample(),
            const Divider(),
            const BasicMutationExample(),
            const MutationVariableKeyExample(),
          ],
        ),
      )),
    );
  }
}
