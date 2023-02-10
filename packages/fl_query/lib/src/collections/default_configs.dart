import 'package:fl_query/src/core/query.dart';
import 'package:fl_query/src/core/retryer.dart';

abstract class DefaultConstants {
  static const RetryConfig retryConfig = RetryConfig(
    maxRetries: 3,
    retryDelay: Duration(seconds: 1),
    timeout: Duration(seconds: 5),
  );

  static const RefreshConfig refreshConfig = RefreshConfig(
    staleDuration: Duration(seconds: 10),
    refreshInterval: Duration(seconds: 5),
  );
}
