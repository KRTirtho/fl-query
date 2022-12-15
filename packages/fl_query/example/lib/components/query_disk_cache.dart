import 'dart:convert';

import 'package:fl_query/fl_query.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

final queryDiskCacheExampleQuery = QueryJob<List<User>, void>(
  queryKey: 'queryDiskCacheExampleQuery',
  serialize: (data) {
    return jsonEncode(data.map((user) => user.toJson()).toList());
  },
  deserialize: (raw) {
    return List.from(jsonDecode(raw))
        .map((user) => User.fromJson(user))
        .toList();
  },
  task: (_, __) async {
    final res =
        await http.get(Uri.parse("https://jsonplaceholder.typicode.com/users"));
    final body = List.from(jsonDecode(res.body))
        .map((user) => User.fromJson(user))
        .toList()
      ..shuffle();
    await Future.delayed(const Duration(seconds: 5));
    return body;
  },
);

class User {
  int? id;
  String? name;
  String? username;
  String? email;

  User({this.id, this.name, this.username, this.email});

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    username = json['username'];
    email = json['email'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['name'] = name;
    data['username'] = username;
    data['email'] = email;
    return data;
  }
}

class QueryDiskCacheExample extends StatelessWidget {
  const QueryDiskCacheExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return QueryBuilder<List<User>, void>(
      job: queryDiskCacheExampleQuery,
      externalData: null,
      builder: (context, query) {
        if (!query.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView.builder(
          shrinkWrap: true,
          itemCount: query.data?.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(query.data![index].name!),
              subtitle: Text(query.data![index].email!),
            );
          },
        );
      },
    );
  }
}
