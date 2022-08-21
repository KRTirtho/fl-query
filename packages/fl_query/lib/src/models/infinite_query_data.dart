class InfiniteQueryData<T extends Object> {
  final Set<T> pages;
  final Set<String> pageParams;

  InfiniteQueryData({
    required this.pages,
    required this.pageParams,
  });
}
