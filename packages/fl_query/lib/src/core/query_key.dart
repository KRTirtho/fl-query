/// Used for defining a unique identifier for a specific query
/// that can be used to read/modify/delete the query from the
/// store
class QueryKey {
  List<String> _key;
  QueryKey(String key) : _key = [key];

  QueryKey.fromList(List<String> key) : _key = key;
  QueryKey.parse(String keyStr) : _key = keyStr.split(".");

  String get key => _key.map((k) => k.replaceAll(".", "")).join(".");

  @override
  String toString() {
    return 'QueryKey("$key")';
  }
}
