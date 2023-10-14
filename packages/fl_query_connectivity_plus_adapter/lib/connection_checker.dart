import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fl_query_connectivity_plus_adapter/lookups/connection_lookup_io.dart'
    if (dart.library.html) 'package:fl_query_connectivity_plus_adapter/lookups/connection_lookup_web.dart';

abstract class ConnectionLookup {
  Future<bool> doesConnectTo(String address);
  Future<bool> isVpnActive();
}

class InternetConnectivityChecker
    with WidgetsBindingObserver, ConnectionLookupMixin {
  final StreamController<bool> controller;

  bool _wasConnected = true;

  bool get isAppPaused =>
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused;

  InternetConnectivityChecker(Duration duration)
      : controller = StreamController<bool>.broadcast() {
    Timer.periodic(duration, (timer) async {
      if (isAppPaused) {
        return;
      }
      await hasConnection();
    });
    Connectivity().onConnectivityChanged.listen((event) async {
      if (isAppPaused) {
        return;
      }
      await hasConnection();
    });
  }

  @override
  didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      await hasConnection();
    }
  }

  Future<bool> hasConnection() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    final hasNetwork = [
      ConnectivityResult.mobile,
      ConnectivityResult.wifi,
      ConnectivityResult.ethernet,
    ].contains(connectivityResult);

    final isVpn =
        connectivityResult == ConnectivityResult.vpn || await isVpnActive();

    final connected = hasNetwork
        ? kIsWeb
            ? await doesConnectTo('/favicon.ico') ||
                await doesConnectTo('/favicon.png') ||
                await doesConnectTo('/favicon.gif')
            : await doesConnectTo('google.com') ||
                await doesConnectTo('www.baidu.com')
        : isVpn;

    if (connected != _wasConnected) {
      _wasConnected = connected;
      controller.add(connected);
    }
    return connected;
  }

  Stream<bool> get onConnectionChanged => controller.stream;
}
