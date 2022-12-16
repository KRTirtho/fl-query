import 'package:connectivity_plus/connectivity_plus.dart';

final _alwaysOnlineConnectivity = AlwaysOnlineConnectivity._();

/// make this singleton
class AlwaysOnlineConnectivity implements Connectivity {
  AlwaysOnlineConnectivity._();

  factory AlwaysOnlineConnectivity() {
    return _alwaysOnlineConnectivity;
  }

  @override
  Future<ConnectivityResult> checkConnectivity() {
    return Future.value(ConnectivityResult.ethernet);
  }

  @override
  Stream<ConnectivityResult> get onConnectivityChanged => Stream.empty();
}
