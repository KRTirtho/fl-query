import 'package:fl_query_devtools/src/widgets/tabs/infinite_query_tab.dart';
import 'package:fl_query_devtools/src/widgets/tabs/mutation_tab.dart';
import 'package:fl_query_devtools/src/widgets/tabs/query_tab.dart';
import 'package:flutter/material.dart';

class DevtoolsRoot extends StatefulWidget {
  final VoidCallback? onClose;
  const DevtoolsRoot({super.key, this.onClose});

  @override
  State<DevtoolsRoot> createState() => _DevtoolsRootState();
}

class _DevtoolsRootState extends State<DevtoolsRoot> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('FlQuery Devtools'),
          actions: [
            IconButton(
              onPressed: widget.onClose,
              icon: const Icon(Icons.close),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Queries'),
              Tab(text: 'Infinite Queries'),
              Tab(text: 'Mutations'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            QueryTab(),
            InfiniteQueryTab(),
            MutationTab(),
          ],
        ),
      ),
    );
  }
}
