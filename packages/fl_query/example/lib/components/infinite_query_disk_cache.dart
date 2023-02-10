import 'dart:convert';

import 'package:fl_query/fl_query.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Todo {
  int? userId;
  int? id;
  String? title;
  bool? completed;

  Todo({this.userId, this.id, this.title, this.completed});

  Todo.fromJson(Map<String, dynamic> json) {
    userId = json['userId'];
    id = json['id'];
    title = json['title'];
    completed = json['completed'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['userId'] = userId;
    data['id'] = id;
    data['title'] = title;
    data['completed'] = completed;
    return data;
  }
}

final infiniteQueryDiskCacheExampleQuery =
    InfiniteQueryJob<List<Todo>, void, int>(
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
    return jsonEncode(data.map((todo) => todo.toJson()).toList());
  },
  deserialize: (raw) {
    return List.from(jsonDecode(raw))
        .map((todo) => Todo.fromJson(todo))
        .toList();
  },
  serializePageParam: (param) => param.toString(),
  deserializePageParam: (rawParam) => int.parse(rawParam),
  task: (_, pageParam, __) async {
    final res = await http.get(
      Uri.parse(
          "https://jsonplaceholder.typicode.com/todos?_start=$pageParam&_end=${pageParam + 5}"),
    );
    final body = List.from(jsonDecode(res.body))
        .map((todo) => Todo.fromJson(todo))
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
                body: InfiniteQueryBuilder<List<Todo>, void, int>(
                  job: infiniteQueryDiskCacheExampleQuery,
                  externalData: null,
                  builder: (context, query) {
                    final data = query.pages
                        .expand((page) => page?.toList() ?? <Todo>[])
                        .toList();
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
                          return CheckboxListTile(
                            value: data[index].completed == true,
                            title: Text(data[index].title ?? ""),
                            dense: true,
                            secondary: Text(data[index].id.toString()),
                            onChanged: null,
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
