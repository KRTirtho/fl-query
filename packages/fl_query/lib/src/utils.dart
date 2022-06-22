import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fl_query/src/query.dart';
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

bool isShallowEqualList(List list1, List list2) {
  return list1.asMap().entries.every((l1Entry) {
    return l1Entry.value == list2[l1Entry.key];
  });
}

bool isShallowEqualSet(Set list1, Set list2) {
  return isShallowEqualList(list1.toList(), list2.toList());
}

bool isShallowEqualMap(Map list1, Map list2) {
  return list1.entries.every((l1Entry) {
    return l1Entry.value == list2[l1Entry.key];
  });
}

bool isShallowEqual(Object obj1, Object obj2) {
  if (obj1 is List && obj2 is List) {
    return isShallowEqualList(obj1, obj2);
  } else if (obj1 is Set && obj2 is Set) {
    return isShallowEqualSet(obj1, obj2);
  } else if (obj1 is Map && obj2 is Map) {
    return isShallowEqualMap(obj1, obj2);
  } else {
    // for other types basically comparing references for non primitive
    // types. And primitives are always compared by value
    return obj1 == obj2;
  }
}

bool isConnectedToInternet(ConnectivityResult result) {
  return [
    ConnectivityResult.ethernet,
    ConnectivityResult.mobile,
    ConnectivityResult.wifi,
  ].contains(result);
}
