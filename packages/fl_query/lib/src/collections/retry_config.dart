class RetryConfig {
  final int maxRetries;
  final Duration retryDelay;

  const RetryConfig({required this.maxRetries, required this.retryDelay});
}
