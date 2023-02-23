import 'package:fl_query_hooks_example/router.dart';
import 'package:fl_query/fl_query.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await QueryClient.initialize(cachePrefix: 'fl_query_example');
  runApp(
    QueryClientProvider(
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: ThemeData(
        colorSchemeSeed: Colors.red[100],
        useMaterial3: true,
      ),
      title: 'FL Query Hooks Example',
      routerConfig: router,
    );
  }
}