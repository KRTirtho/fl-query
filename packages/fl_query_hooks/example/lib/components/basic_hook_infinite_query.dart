import 'dart:convert';

import 'package:fl_query_hooks/fl_query_hooks.dart';
import 'package:flutter/material.dart';
import 'package:fl_query/fl_query.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:http/http.dart' as http;

final infiniteQueryHookJob = InfiniteQueryJob<Map, void, int>(
  queryKey: "infinite-posts",
  initialParam: 1,
  task: (queryKey, pageParam, externalData) async {
    return jsonDecode(
      (await http.get(
        Uri.parse("https://jsonplaceholder.typicode.com/posts/$pageParam"),
      ))
          .body,
    );
  },
  getNextPageParam: (lastPage, lastParam) {
    return lastParam + 1;
  },
  getPreviousPageParam: (lastPage, lastParam) {
    return lastParam - 1;
  },
);

class BasicHookInfiniteQueryExample extends HookWidget {
  const BasicHookInfiniteQueryExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final infiniteQuery = useInfiniteQuery(
      job: infiniteQueryHookJob,
      externalData: null,
    );

    return Scaffold(
      appBar: AppBar(),
      body: Stack(
        children: [
          ListView.builder(
            itemCount: infiniteQuery.pages.length,
            itemBuilder: (context, index) {
              final page = infiniteQuery.pages[index];
              return ListTile(
                title: Text(page?["title"] ?? ""),
                subtitle: Text(page?["body"] ?? ""),
              );
            },
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () => infiniteQuery.refetchPages(),
                ),
                IconButton(
                  icon: const Icon(Icons.get_app_rounded),
                  onPressed: () => infiniteQuery.fetchNextPage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
