import 'dart:convert';

Object? primitivifyValue(data) {
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
        return data;
      } catch (e) {
        return "[Parsing Error]: ${data.runtimeType} contains unsupported non-primitive and non-jsonEncodable value";
      }
    default:
      return data.toString();
  }
}
