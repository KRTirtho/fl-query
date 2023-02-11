class RetryConfig {
  final int maxRetries;
  final Duration retryDelay;
  final Duration timeout;

  const RetryConfig({
    required this.maxRetries,
    required this.retryDelay,
    required this.timeout,
  });
}
