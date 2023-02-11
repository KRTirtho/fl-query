class JsonConfig<T> {
  final Map<String, dynamic> Function(T data) toJson;
  final T Function(Map<String, dynamic> json) fromJson;

  const JsonConfig({
    required this.toJson,
    required this.fromJson,
  });
}
