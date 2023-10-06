import 'package:fl_query/fl_query.dart';
import 'package:fl_query_devtools/src/helpers/jsonify_value.dart';
import 'package:fl_query_devtools/src/helpers/primitvify_value.dart';
import 'package:fl_query_devtools/src/widgets/explorers/explorer_view.dart';
import 'package:fl_query_devtools/src/widgets/query_tile.dart';
import 'package:flutter/material.dart';

class QueryTab extends StatefulWidget {
  const QueryTab({super.key});

  @override
  State<QueryTab> createState() => _QueryTabState();
}

class _QueryTabState extends State<QueryTab> {
  String? _selectedQueryKey;

  @override
  Widget build(BuildContext context) {
    final client = QueryClient.of(context);

    return LayoutBuilder(builder: (context, constrains) {
      return Row(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: client.cache.queries.length,
              itemBuilder: (context, index) {
                final query = client.cache.queries.elementAt(index);
                return QueryListenable(
                  query.key,
                  builder: (context, query) {
                    if (query == null) {
                      return const SizedBox.shrink();
                    }

                    return QueryTile(
                      title: query.key,
                      isLoading: query.isLoading,
                      hasError: query.hasError,
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
                  child: QueryListenable(_selectedQueryKey ?? '',
                      builder: (context, query) {
                    if (query == null) {
                      return const SizedBox.shrink();
                    }

                    return ExplorerView(
                      title: query.key,
                      data: {
                        'data': jsonifyValue(query.data, query.jsonConfig),
                        'errors': primitivifyValue(query.error),
                        'stale': query.state.isStale,
                        'updatedAt': query.state.updatedAt.toString(),
                        'isLoading': query.isLoading,
                        'isRefreshing': query.isRefreshing,
                        'isInactive': query.isInactive,
                        'isInitial': query.isInitial,
                        'refreshConfig': query.refreshConfig.toJson(),
                        'retryConfig': query.retryConfig.toJson()
                      },
                      onClose: () {
                        setState(() {
                          _selectedQueryKey = null;
                        });
                      },
                    );
                  }),
                ),
              );
            }),
          ),
        ],
      );
    });
  }
}
