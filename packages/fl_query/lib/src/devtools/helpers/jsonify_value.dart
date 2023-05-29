import 'dart:convert';

import 'package:fl_query/src/collections/json_config.dart';

Object? jsonifyValue(data, JsonConfig? jsonConfig) {
  switch (data.runtimeType) {
    case String:
    case int:
    case double:
    case bool:
    case Null:
      return data;
    case Iterable:
    case Map:
      try {
        jsonEncode(data);
        return data is Iterable ? data.toList() : data;
      } catch (e) {
        return "[Parsing Error]: ${data.runtimeType} contains unsupported non-primitive and non-jsonEncodable value";
      }
    default:
      if (jsonConfig == null) {
        return "$data"
            "\nProvide `jsonConfig: JsonConfig(...)` to enable Json view for data";
      } else {
        return (jsonConfig as dynamic).toJson(data);
      }
  }
}
