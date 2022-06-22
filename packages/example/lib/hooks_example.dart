import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:fl_query/fl_query_hooks.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class HookExample extends HookWidget {
  const HookExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final query = useQuery(job: successJob, externalData: null);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Running the 1st example but with hooks instead"),
      ),
      body: !query.hasData || query.isLoading || query.isRefetching
          ? const CircularProgressIndicator()
          : TextButton(
              child: Text(query.data!),
              onPressed: () async {
                await query.refetch();
              },
            ),
    );
  }
}
