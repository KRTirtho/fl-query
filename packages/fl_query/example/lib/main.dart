import 'package:fl_query/fl_query.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await QueryClient.initialize();
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
    return MaterialApp(
      home: Scaffold(
        body: QueryBuilder<String, void, String>(
          const ValueKey('hello'),
          () {
            return Future.delayed(
              const Duration(seconds: 5),
              () => 'Hello World!',
            );
          },
          initial: 'Hello',
          // jsonConfig: JsonConfig(
          //   fromJson: (json) => json['data'],
          //   toJson: (data) => {'data': data},
          // ),
          builder: (context, query) {
            if (query.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (query.hasError) {
              return Center(
                child: Text(query.error.toString()),
              );
            }
            return Center(
              child: Text(query.data),
            );
          },
        ),
      ),
    );
  }
}
