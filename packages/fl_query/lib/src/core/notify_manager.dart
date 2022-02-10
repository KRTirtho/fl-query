// TYPES

import 'package:fl_query/src/core/utils.dart';

typedef NotifyCallback = void Function();

typedef NotifyFunction = void Function(void Function() callback);

typedef BatchNotifyFunction = void Function(void Function() callback);

class _NotifyManager {
  List<NotifyCallback> _queue;
  int _transactions;
  late NotifyFunction _notifyFn;
  late BatchNotifyFunction _batchNotifyFn;

  _NotifyManager()
      : _queue = [],
        _transactions = 0 {
    _notifyFn = (void Function() callback) {
      callback();
    };

    _batchNotifyFn = (void Function() callback) {
      callback();
    };
  }

  T batch<T>(T Function() callback) {
    T result;
    _transactions++;
    try {
      result = callback();
    } finally {
      _transactions--;
      if (_transactions == 0) {
        flush();
      }
    }
    return result;
  }

  schedule(NotifyCallback callback) {
    if (_transactions > 0) {
      _queue.add(callback);
    } else {
      scheduleMicrotask((val) {
        _notifyFn(callback);
      });
    }
  }

  /// All calls to the wrapped function will be batched.
  T batchCalls<T extends void Function(List? args)>(T callback) {
    void fn(List? args) {
      schedule(() {
        callback(args);
      });
    }

    ;
    return fn as T;
  }

  void flush() {
    var queue = _queue;
    _queue = [];
    if (queue.isNotEmpty) {
      scheduleMicrotask((val) {
        _batchNotifyFn(() {
          queue.forEach((fn) {
            _notifyFn(fn);
          });
        });
      });
    }
  }

  ///Use this method to set a custom notify function.
  void setNotifyFunction(NotifyFunction fn) {
    _notifyFn = fn;
  }

  /// Use this method to set a custom function to batch notifications
  /// together into a single tick.
  /// By default React Query will use the batch function provided by
  /// ReactDOM or React Native.
  void setBatchNotifyFunction(BatchNotifyFunction fn) {
    _batchNotifyFn = fn;
  }
}

// SINGLETON

_NotifyManager notifyManager = new _NotifyManager();
