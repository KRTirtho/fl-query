import 'dart:convert';

import 'package:fl_query/fl_query.dart';
import 'package:fl_query_example/components/query_disk_cache.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

final infiniteQueryDiskCacheExampleQuery =
    InfiniteQueryJob<List<User>, void, int>(
  queryKey: 'infiniteQueryDiskCacheExampleQuery',
  initialParam: 0,
  getNextPageParam: (lastPage, lastParam) {
    if (lastPage.length < 5) return null;
    return lastParam + 5;
  },
  getPreviousPageParam: (firstPage, firstParam) {
    if (firstParam == 0) return null;
    return firstParam - 5;
  },
  serialize: (data) {
    return jsonEncode(data.map((user) => user.toJson()).toList());
  },
  deserialize: (raw) {
    return List.from(jsonDecode(raw))
        .map((user) => User.fromJson(user))
        .toList();
  },
  serializePageParam: (param) => param.toString(),
  deserializePageParam: (rawParam) => int.parse(rawParam),
  task: (_, pageParam, __) async {
    final res = await http.get(
      Uri.parse(
          "https://jsonplaceholder.typicode.com/users?_start=$pageParam&_end=${pageParam + 5}"),
    );
    final body = List.from(jsonDecode(res.body))
        .map((user) => User.fromJson(user))
        .toList()
      ..shuffle();
    if (pageParam == 0) await Future.delayed(const Duration(seconds: 5));
    return body;
  },
);

class InfiniteQueryDiskCacheExample extends StatefulWidget {
  const InfiniteQueryDiskCacheExample({Key? key}) : super(key: key);

  @override
  State<InfiniteQueryDiskCacheExample> createState() =>
      _InfiniteQueryDiskCacheExampleState();
}

class _InfiniteQueryDiskCacheExampleState
    extends State<InfiniteQueryDiskCacheExample> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text("Infinite Query Disk Cache Example"),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) {
              return Scaffold(
                appBar: AppBar(
                    title: const Text("Infinite Query Disk Cache Example")),
                body: InfiniteQueryBuilder<List<User>, void, int>(
                  job: infiniteQueryDiskCacheExampleQuery,
                  externalData: null,
                  builder: (context, query) {
                    final data =
                        query.pages.expand((page) => page!.toList()).toList();
                    return Scaffold(
                      floatingActionButton: FloatingActionButton(
                        child: const Icon(Icons.download_rounded),
                        onPressed: () {
                          if (query.hasNextPage == true) {
                            query.fetchNextPage();
                          }
                        },
                      ),
                      body: ListView.builder(
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(data[index].name!),
                            subtitle: Text(data[index].email!),
                          );
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
