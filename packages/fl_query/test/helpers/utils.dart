import 'package:fl_query/src/core/core.dart';
import 'package:uuid/uuid.dart';

Uuid uuid = Uuid();

QueryKey queryKey() {
  return QueryKey("query_${uuid.v4()}");
}
