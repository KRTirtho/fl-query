import 'package:fl_query/fl_query.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Simple hook based shorthand for [QueryBowl.of(context)]
QueryBowl useQueryBowl() {
  final context = useContext();

  return QueryBowl.of(context);
}
