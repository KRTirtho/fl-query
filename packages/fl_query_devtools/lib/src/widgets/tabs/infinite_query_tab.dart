import 'package:fl_query/fl_query.dart';
import 'package:fl_query_devtools/src/helpers/jsonify_value.dart';
import 'package:fl_query_devtools/src/helpers/primitvify_value.dart';
import 'package:fl_query_devtools/src/widgets/explorers/explorer_view.dart';
import 'package:fl_query_devtools/src/widgets/query_tile.dart';
import 'package:flutter/material.dart';

class InfiniteQueryTab extends StatefulWidget {
  const InfiniteQueryTab({super.key});

  @override
  State<InfiniteQueryTab> createState() => _InfiniteQueryTabState();
}

class _InfiniteQueryTabState extends State<InfiniteQueryTab> {
  String? _selectedQueryKey;

  @override
  Widget build(BuildContext context) {
    final client = QueryClient.of(context);

    return LayoutBuilder(builder: (context, constrains) {
      return Row(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: client.cache.infiniteQueries.length,
              itemBuilder: (context, index) {
                final infiniteQuery =
                    client.cache.infiniteQueries.elementAt(index);
                return InfiniteQueryListenable(
                  infiniteQuery.key,
                  builder: (context, query) {
                    if (query == null) {
                      return const SizedBox.shrink();
                    }

                    return QueryTile(
                      title: query.key,
                      isLoading: query.isLoadingPage,
                      hasError: query.hasErrors,
                      onTap: () {
                        setState(() {
                          _selectedQueryKey = query.key;
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.bounceInOut,
            child: Builder(builder: (context) {
              return SizedBox(
                width: _selectedQueryKey == null
                    ? 0
                    : constrains.biggest.width * 0.5,
                child: SizedBox.expand(
                  child: InfiniteQueryListenable(
                    _selectedQueryKey ?? '',
                    builder: (context, query) {
                      if (query == null) {
                        return SizedBox.shrink();
                      }

                      return ExplorerView(
                        title: query.key,
                        data: {
                          'pages': query.state.pages.map((page) {
                            return {
                              "pageParam": primitivifyValue(page.page),
                              "data": jsonifyValue(page.data, query.jsonConfig),
                              "errors": primitivifyValue(page.error),
                              "stale": page.isStale,
                              "updatedAt": page.updatedAt.toString(),
                            };
                          }).toList(),
                          'isLoadingPage': query.isLoadingPage,
                          'isRefreshingPage': query.isRefreshingPage,
                          'isInactive': query.isInactive,
                          'refreshConfig': query.refreshConfig.toJson(),
                          'retryConfig': query.retryConfig.toJson()
                        },
                        onClose: () {
                          setState(() {
                            _selectedQueryKey = null;
                          });
                        },
                      );
                    },
                  ),
                ),
              );
            }),
          ),
        ],
      );
    });
  }
}
