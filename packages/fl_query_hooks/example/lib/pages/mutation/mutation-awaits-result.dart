import 'package:fl_query_hooks/fl_query_hooks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class MutationAwaitsResult extends HookWidget {
  const MutationAwaitsResult({super.key});

  @override
  Widget build(BuildContext context) {
    final mutation = useMutation('mutation2', (variables) {
      return Future.delayed(const Duration(seconds: 2), () => 'result value');
    }, onData: (data, _) {
      print('done in onData: $data');
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mutation awaits result'),
      ),
      body: Center(
        child: ElevatedButton(
          child: const Text('Run'),
          onPressed: () async {
            print('clicked');
            final result = await mutation.mutate(null);
            print(result);
          },
        ),
      ),
    );
  }
}