import 'package:fl_query/fl_query.dart';
import 'package:fl_query_devtools/src/widgets/query_tile.dart';
import 'package:flutter/material.dart';

class MutationTab extends StatefulWidget {
  const MutationTab({super.key});

  @override
  State<MutationTab> createState() => _MutationTabState();
}

class _MutationTabState extends State<MutationTab> {
  @override
  Widget build(BuildContext context) {
    final client = QueryClient.of(context);

    return ListView.builder(
      itemCount: client.cache.mutations.length,
      itemBuilder: (context, index) {
        final mutation = client.cache.mutations.elementAt(index);
        return QueryTile(
          title: mutation.key,
          isLoading: mutation.isMutating,
          hasError: mutation.hasError,
        );
      },
    );
  }
}
