import 'dart:convert';

import 'package:flutter/material.dart';
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
                  itemCount: infiniteQuery.pages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Text(
                        """
    InfiniteQuery properties

    isFetchingNextPage: ${infiniteQuery.isFetchingNextPage}
    isFetchingPreviousPage: ${infiniteQuery.isFetchingPreviousPage}
    isLoading: ${infiniteQuery.isLoading}
    isRefetching: ${infiniteQuery.isRefetching}
    isError: ${infiniteQuery.isError}
    isSuccess: ${infiniteQuery.isSuccess}
    isIdle: ${infiniteQuery.isIdle}
    isInactive: ${infiniteQuery.isInactive}
    isStale: ${infiniteQuery.isStale}
    fetched: ${infiniteQuery.fetched}
    
    hasData: ${infiniteQuery.hasData}
    hasError: ${infiniteQuery.hasError}
    hasNextPage: ${infiniteQuery.hasNextPage}
    hasPreviousPage: ${infiniteQuery.hasPreviousPage}

    refetchCount: ${infiniteQuery.refetchCount}
    retryAttempts: ${infiniteQuery.retryAttempts}
    updatedAt: ${infiniteQuery.updatedAt}
                    """,
                      );
                    }
                    final page = infiniteQuery.pages[index - 1];
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
            );
          }),
    );
  }
}
