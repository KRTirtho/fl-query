import 'dart:convert';

import 'package:fl_query_hooks/fl_query_hooks.dart';
import 'package:fl_query_hooks_example/models/product.dart';
import 'package:fl_query/fl_query.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:http/http.dart';

class InfiniteQueryPageWidget extends HookWidget {
  const InfiniteQueryPageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = useScrollController();
    final query = useInfiniteQuery<PagedProducts, ClientException, int>(
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
      jsonConfig: JsonConfig(
        fromJson: (json) => PagedProducts.fromJson(json),
        toJson: (data) => data.toJson(),
      ),
    );

    useEffect(() {
      listener() async {
        if (controller.position.pixels == controller.position.maxScrollExtent) {
          final query = QueryClient.of(context).getInfiniteQuery("products");
          await query?.fetchNext();
        }
      }

      controller.addListener(listener);

      return () => controller.removeListener(listener);
    }, [controller]);

    final products = query.pages.map((e) => e.products).expand((e) => e);

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
      body: !query.hasPages
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
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
    );
  }
}
