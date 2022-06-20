import 'package:fl_query/query.dart';
import 'package:uuid/uuid.dart';

Future<void> callQueryListeners<T>(Set<QueryListener<T>> listeners, T data) {
  return Future.wait(listeners.map(
    (listener) => Future.value(listener(data)),
  ));
  // for (final listener in listeners) {
  //   await listener(data);
  // }
}

const uuid = Uuid();
