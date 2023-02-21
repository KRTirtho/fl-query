mixin Invalidation {
  DateTime get updatedAt;
  Duration get staleDuration;

  bool get isStale => DateTime.now().difference(updatedAt) > staleDuration;
}
