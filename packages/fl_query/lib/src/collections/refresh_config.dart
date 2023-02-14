class RefreshConfig {
  final Duration staleDuration;
  final Duration refreshInterval;
  final bool refreshOnMount;
  final bool refreshOnQueryFnChange;

  const RefreshConfig({
    required this.staleDuration,
    required this.refreshInterval,
    required this.refreshOnMount,
    required this.refreshOnQueryFnChange,
  });
}
