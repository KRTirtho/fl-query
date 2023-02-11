class RefreshConfig {
  final Duration staleDuration;
  final Duration refreshInterval;
  final bool refreshOnMount;

  const RefreshConfig({
    required this.staleDuration,
    required this.refreshInterval,
    required this.refreshOnMount,
  });
}
