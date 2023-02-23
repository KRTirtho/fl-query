import 'package:fl_query/fl_query.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

QueryClient useQueryClient() {
  final context = useContext();
  return QueryClient.of(context);
}
