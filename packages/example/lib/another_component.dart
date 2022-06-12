import 'package:fl_query/query_bowl.dart';
import 'package:flutter/material.dart';

class AnotherComponent extends StatelessWidget {
  const AnotherComponent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lol = QueryBowl.of(context).getQuery<String, void>("greetings");
    final deadQuery =
        QueryBowl.of(context).getQuery<String, String>("external_data");
    if (lol?.data == null) return const CircularProgressIndicator();
    return Text(
      "${lol!.data!} from AnotherComponent\nDeadQuery (It should be null after 10 seconds): ${deadQuery?.data}",
    );
  }
}
