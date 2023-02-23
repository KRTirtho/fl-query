import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FL Query Example'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Query'),
            onTap: () => GoRouter.of(context).push('/query'),
          ),
          ListTile(
            title: const Text('Infinite Query'),
            onTap: () => GoRouter.of(context).push('/infinite-query'),
          ),
          ListTile(
            title: const Text('Mutation'),
            onTap: () => GoRouter.of(context).push('/mutation'),
          ),
        ],
      ),
    );
  }
}
