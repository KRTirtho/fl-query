import 'dart:async';

import 'package:fl_query/src/collections/retry_config.dart';

mixin Retryer<T, E> {
  void retryOperation(
    FutureOr<T?> Function() operation, {
    required RetryConfig config,
    required void Function(T?) onSuccessful,
    required void Function(E?) onFailed,
  }) async {
    for (int attempts = 0; attempts < config.maxRetries; attempts++) {
      final completer = Completer<T?>();
      await Future.delayed(
        attempts == 0 ? Duration.zero : config.retryDelay,
        operation,
      ).then(completer.complete).catchError(completer.completeError);
      try {
        final result = await completer.future;
        onSuccessful(result);
        break;
      } catch (e) {
        if (attempts == config.maxRetries - 1 && e is E?) {
          onFailed(e as E?);
        }
      }
    }
  }
}
