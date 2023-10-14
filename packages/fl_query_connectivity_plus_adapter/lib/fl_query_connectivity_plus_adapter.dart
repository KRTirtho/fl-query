library fl_query_connectivity_plus_adapter;

import 'package:fl_query/fl_query.dart';
import 'package:fl_query_connectivity_plus_adapter/connection_checker.dart';

/// A [ConnectivityAdapter] that uses the `connectivity_plus` package.
class FlQueryConnectivityPlusAdapter extends ConnectivityAdapter {
  final InternetConnectivityChecker _adapter;
  FlQueryConnectivityPlusAdapter({
    Duration pollingDuration = const Duration(seconds: 30),
  }) : _adapter = InternetConnectivityChecker(pollingDuration);

  @override
  Future<bool> get isConnected async {
    return await _adapter.hasConnection();
  }

  @override
  Stream<bool> get onConnectivityChanged => _adapter.onConnectionChanged;
}
