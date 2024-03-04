import 'dart:convert';

import 'package:fl_query_hooks/fl_query_hooks.dart';
import 'package:fl_query_hooks_example/models/product.dart';
import 'package:fl_query/fl_query.dart';
import 'package:fl_query_hooks_example/pages/query.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:http/http.dart';


/// Query is loaded only once, and shared between all widgets

Query<String, dynamic> useSharedQuery() {
  return useQuery<String, dynamic>(
    'multiple-queries',
    () {
      print('Loading query');
      return Future.delayed(const Duration(seconds: 2), () => 'Hello');
    },
  );
}

class MultipleQueries extends HookWidget {
  const MultipleQueries({super.key});

  @override
  Widget build(BuildContext context) {
    final widgets = useState(0);

    useEffect(() {
      Future.delayed(Duration(seconds: 1)).then((value) => widgets.value++);
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Multiple queries'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              widgets.value++;
            },
            child: const Text('Add widget'),
          ),
          const SecondWidget(),
          ...List.generate(widgets.value, (index) {
            return const SecondWidget();
          })
        ],
      ),
    );
  }
}

class SecondWidget extends HookWidget {
  const SecondWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final query = useSharedQuery();

    if (query.isLoading)
      return const Center(child: CircularProgressIndicator());
    if (query.hasError) return Center(child: Text(query.error.toString()));
    if (query.hasData) return Center(child: Text(query.data ?? ""));
    return const SizedBox();
  }
}
