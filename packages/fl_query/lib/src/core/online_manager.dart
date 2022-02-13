import 'package:fl_query/src/core/subscribable.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

typedef SetupFn = void Function()? Function(
    void Function([bool? online]) setOnline);

class OnlineManager extends Subscribable {
  bool? _online;
  void Function()? _cleanup;
  SetupFn? _setup;

  OnlineManager([InternetConnectionChecker? connectionChecker]) {
    connectionChecker ??= InternetConnectionChecker();
    _setup = (listener) {
      var subscription =
          connectionChecker!.onStatusChange.listen((status) => listener());
      return () {
        subscription.cancel();
      };
    };
  }

  @override
  void onSubscribe() {
    if (_cleanup == null) {
      setEventListener(_setup!);
    }
  }

  @override
  void onUnsubscribe() {
    if (!hasListeners()) {
      _cleanup?.call();
      _cleanup = null;
    }
  }

  void setEventListener(SetupFn setup) {
    _setup = setup;
    _cleanup?.call();
    _cleanup = setup(([bool? online]) {
      if (online != null) {
        setOnline(online);
      } else {
        onOnline();
      }
    });
  }

  void setOnline(bool? online) {
    _online = online;
    if (online != null && online) {
      onOnline();
    }
  }

  void onOnline() {
    listeners.forEach((listener) {
      listener();
    });
  }

  Future<bool> isOnline() {
    if (_online != null) {
      return Future.value(_online!);
    }

    return InternetConnectionChecker().hasConnection;
  }
}

OnlineManager onlineManager = OnlineManager();
