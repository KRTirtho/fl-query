import 'dart:async';

import 'package:async/async.dart';
import 'package:fl_query/src/collections/retry_config.dart';
import 'package:flutter/material.dart';

mixin Retryer<T, E> {
  Future<void> retryOperation(
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
      } catch (e, stack) {
        if (e is E?) {
          if (attempts == config.maxRetries - 1) {
            onFailed(e as E?);
          }
        } else {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: e,
              library: 'fl_query',
              context: ErrorDescription('retryOperation'),
              stack: stack,
            ),
          );
        }
      }
    }
  }

  CancelableOperation<void> cancellableRetryOperation(
    FutureOr<T?> Function() operation, {
    required RetryConfig config,
    required void Function(T?) onSuccessful,
    required void Function(E?) onFailed,
  }) {
    return CancelableOperation.fromFuture(
      retryOperation(
        operation,
        config: config,
        onSuccessful: onSuccessful,
        onFailed: onFailed,
      ),
    );
  }
}
