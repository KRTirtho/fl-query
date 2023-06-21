library fl_query_connectivity_plus_adapter;

import 'package:fl_query/fl_query.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// A [ConnectivityAdapter] that uses the `connectivity_plus` package.
class FlQueryConnectivityPlusAdapter extends ConnectivityAdapter {
  @override
  Future<bool> get isConnected async {
    final connection = await Connectivity().checkConnectivity();

    switch (connection) {
      case ConnectivityResult.bluetooth:
      case ConnectivityResult.none:
        return false;
      default:
        return true;
    }
  }

  @override
  Stream<bool> get onConnectivityChanged =>
      Connectivity().onConnectivityChanged.map((event) {
        switch (event) {
          case ConnectivityResult.bluetooth:
          case ConnectivityResult.none:
            return false;
          default:
            return true;
        }
      });
}
