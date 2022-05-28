import 'package:fl_query/query_bowl.dart';
import 'package:flutter/material.dart';

class AnotherComponent extends StatelessWidget {
  const AnotherComponent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lol = QueryBowl.of(context).getQuery<String>("greetings");
    if (lol?.data == null) return const CircularProgressIndicator();
    return Text("${lol!.data!} from AnotherComponent");
  }
}
