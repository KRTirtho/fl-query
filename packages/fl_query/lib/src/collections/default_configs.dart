import 'package:fl_query/src/collections/refresh_config.dart';
import 'package:fl_query/src/collections/retry_config.dart';

abstract class DefaultConstants {
  static const RetryConfig retryConfig = RetryConfig(
    maxRetries: 3,
    retryDelay: Duration(seconds: 1),
  );

  static const RefreshConfig refreshConfig = RefreshConfig(
    staleDuration: Duration(minutes: 2, milliseconds: 250),
    refreshInterval: Duration.zero,
    refreshOnMount: false,
    refreshOnQueryFnChange: false,
  );

  static const Duration cacheDuration = Duration(minutes: 5);
}