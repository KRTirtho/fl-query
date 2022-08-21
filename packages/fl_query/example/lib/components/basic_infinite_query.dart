import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fl_query/fl_query.dart';
import 'package:http/http.dart' as http;

final infiniteQueryJob = InfiniteQueryJob<Map, void, int>(
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

class BasicInfiniteQueryExample extends StatelessWidget {
  const BasicInfiniteQueryExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: InfiniteQueryBuilder<Map, void, int>(
          job: infiniteQueryJob,
          externalData: null,
          builder: (context, infiniteQuery) {
            return Stack(
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
                  child: IconButton(
                    icon: const Icon(Icons.get_app_rounded),
                    onPressed: () => infiniteQuery.fetchNextPage(),
                  ),
                ),
              ],
            );
          }),
    );
  }
}
