abstract class ConnectivityAdapter {
  Future<bool> get isConnected;

  Stream<bool> get onConnectivityChanged;
}
