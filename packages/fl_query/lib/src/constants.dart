import 'package:fl_query/src/query.dart';
import 'package:fl_query/src/retryer.dart';

abstract class Constants {
  static const RetryConfig defaultRetryConfig = RetryConfig(
    maxRetries: 3,
    retryDelay: Duration(seconds: 1),
    timeout: Duration(seconds: 5),
  );

  static const RefreshConfig defaultRefreshConfig = RefreshConfig(
    staleDuration: Duration(seconds: 10),
    refreshInterval: Duration(seconds: 5),
  );
}
