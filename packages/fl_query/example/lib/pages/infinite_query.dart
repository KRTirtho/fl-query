import 'dart:convert';

import 'package:fl_query_example/models/product.dart';
import 'package:fl_query/fl_query.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

class InfiniteQueryPageWidget extends StatefulWidget {
  const InfiniteQueryPageWidget({super.key});

  @override
  State<InfiniteQueryPageWidget> createState() =>
      _InfiniteQueryPageWidgetState();
}

class _InfiniteQueryPageWidgetState extends State<InfiniteQueryPageWidget> {
  final controller = ScrollController();

  @override
  void initState() {
    super.initState();
    controller.addListener(() async {
      if (controller.position.pixels == controller.position.maxScrollExtent) {
        final query = QueryClient.of(context).getInfiniteQuery("products");
        await query?.fetchNext();
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Infinite Query'),
      ),
      floatingActionButton:
          InfiniteQueryListenable("products", builder: (context, query) {
        return FloatingActionButton(
          onPressed: () {
            query?.fetchNext();
          },
          child: Text(query?.pages.length.toString() ?? "-69"),
        );
      }),
      body: InfiniteQueryBuilder<PagedProducts, ClientException, int>(
        "products",
        (page) async {
          final res = await get(Uri.parse(
            "https://dummyjson.com/products?limit=10&skip=${page * 10}",
          ));

          if (res.statusCode == 200) {
            return PagedProducts.fromJson(jsonDecode(res.body));
          } else {
            throw ClientException(res.statusCode.toString(), res.request?.url);
          }
        },
        nextPage: (lastPage, lastPageData) {
          /// returning [null] will set [hasNextPage] to [false]
          if (lastPageData.products.length < 10) return null;
          return lastPage + 1;
        },
        initialPage: 0,
        // jsonConfig: JsonConfig(
        //   fromJson: (json) => PagedProducts.fromJson(json),
        //   toJson: (data) => data.toJson(),
        // ),
        builder: (context, query) {
          final products = query.pages.map((e) => e.products).expand((e) => e);

          return query.resolve(
            (data) => ListView(
              controller: controller,
              children: [
                for (final product in products)
                  ListTile(
                    title: Text(product.title),
                    subtitle: Text(product.description),
                    leading: Image.network(product.thumbnail),
                  ),
                if (query.hasNextPage)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
                if (query.hasErrors)
                  ...query.errors.map((e) => Text(e.message)).toList(),
              ],
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error) => const Center(
              child: Text("Sorry! There was an error :'("),
            ),
            offline: () => const Center(
              child: Text("Yo. You're offline. Are you in a jungle?"),
            ),
          );
        },
      ),
    );
  }
}
