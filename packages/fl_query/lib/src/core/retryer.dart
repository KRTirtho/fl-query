import 'dart:async';

import 'dart:math' show pow, min;

import 'package:fl_query/src/core/online_manager.dart';

typedef ShouldRetryFunction<TError> = int Function(
  int failureCount,
  TError error,
);
typedef RetryDelayFunction<TError> = double Function(
  int failureCount,
  TError error,
);

double defaultRetryDelay(int failureCount) {
  return min(pow(1000 * 2, failureCount), 30000).toDouble();
}

abstract class Cancelable {
  void cancel();
}

bool isCancelable(value) {
  return value is Cancelable;
}

class CancelledError {
  bool? revert;
  bool? silent;
  CancelledError({this.revert, this.silent});

  @override
  String toString() {
    return "CancelledError(revert: $revert, silent: $silent)";
  }
}

bool isCancelledError(value) {
  return value is CancelledError;
}

typedef OnError<TError> = void Function(TError error);
typedef OnData<TData extends Map<String, dynamic>> = void Function(TData data);

class Retryer<TData extends Map<String, dynamic>, TError> {
  late void Function({bool? revert, bool? silent}) cancel;
  late void Function() cancelRetry;
  late void Function() continueRetry;
  late void Function() continueFn;
  // late Future<TData> future;
  late Completer<TData> completer;
  int failureCount;
  bool isPaused;
  bool isResolved;
  bool isTransportCancelable;

  // config options for the retryer
  FutureOr<TData> Function() fn;
  void Function()? _abort;
  OnError<TError>? onError;
  OnData<TData>? onSuccess;
  void Function(int failureCount, TError error)? onFail;
  void Function()? onPause;
  void Function()? onContinue;
  ShouldRetryFunction<TError>? retry;
  RetryDelayFunction<TError>? retryDelay;

  Retryer({
    required this.fn,
    void Function()? abort,
    this.onError,
    this.onSuccess,
    this.onFail,
    this.onPause,
    this.onContinue,
    this.retry,
    this.retryDelay,
  })  : _abort = abort,
        failureCount = 0,
        isPaused = false,
        isResolved = false,
        isTransportCancelable = false {
    bool cancelRetry = false;
    void Function({bool? revert, bool? silent})? cancelFn;
    void Function([dynamic value])? continueFn;
    cancel = ({bool? revert, bool? silent}) {
      cancelFn?.call();
    };

    this.cancelRetry = () {
      cancelRetry = true;
    };

    this.continueRetry = () {
      cancelRetry = false;
    };

    this.continueFn = () => continueFn?.call();

    completer = Completer<TData>();

    // this.future = completer.future;

    resolve(value) {
      if (!this.isResolved) {
        this.isResolved = true;
        onSuccess?.call(value);
        continueFn?.call();
        if (!completer.isCompleted) completer.complete(value);
      }
    }

    reject(value) {
      if (!this.isResolved) {
        this.isResolved = true;
        onError?.call(value);
        continueFn?.call();
        if (!completer.isCompleted) completer.completeError(value);
      }
    }

    pause() {
      Completer pauseCompleter = Completer();
      if (!pauseCompleter.isCompleted) continueFn = pauseCompleter.complete;
      this.isPaused = true;
      onPause?.call();
      return pauseCompleter.future.then((val) {
        continueFn = null;
        this.isPaused = false;
        onContinue?.call();
      });
    }

    run() {
      // Do nothing if already resolved
      if (this.isResolved) {
        return;
      }
      var promiseOrValue;

      // Execute query
      try {
        promiseOrValue = fn();
      } catch (error) {
        promiseOrValue = Future.error(error);
      }

      // Create callback to cancel this fetch
      cancelFn = ({bool? revert, bool? silent}) {
        if (!this.isResolved) {
          reject(new CancelledError(revert: revert, silent: silent));

          abort?.call();

          // Cancel transport if supported
          if (isCancelable(promiseOrValue)) {
            try {
              promiseOrValue.cancel();
            } catch (error) {}
          }
        }
      };

      // Check if the transport layer support cancellation
      this.isTransportCancelable = isCancelable(promiseOrValue);
      Future.value(promiseOrValue).then(resolve).catchError((error) {
        // Stop if the fetch is already resolved
        if (this.isResolved) return;
        // Do we need to retry the request?
        int _retry = retry?.call(failureCount, error) ?? 3;
        double _retryDelay = retryDelay?.call(failureCount, error) ??
            defaultRetryDelay(failureCount);
        bool shouldRetry = _retry > 0 && _retry > failureCount;
        if (cancelRetry || !shouldRetry) {
          // We are done if the query does not need to be retried
          reject(error);
          return;
        }
        this.failureCount++;

        // Notify on fail
        onFail?.call(this.failureCount, error);
        Future.delayed(Duration(milliseconds: _retryDelay.toInt()))
            .then((val) async {
          if (!await onlineManager.isOnline()) {
            return pause();
          }
        }).then((val) {
          if (cancelRetry) {
            reject(error);
          } else {
            run();
          }
        });
      });
    }

    // Start loop
    run();
  }
}
