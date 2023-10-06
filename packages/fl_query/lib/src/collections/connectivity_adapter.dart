abstract class ConnectivityAdapter {
  bool _isConnectedSync;

  ConnectivityAdapter() : _isConnectedSync = true {
    isConnected.then((c) => _isConnectedSync = c);
    onConnectivityChanged.listen((isConnected) {
      _isConnectedSync = isConnected;
    });
  }

  bool get isConnectedSync => _isConnectedSync;

  Future<bool> get isConnected;

  Stream<bool> get onConnectivityChanged;
}

class NoOpConnectivityAdapter extends ConnectivityAdapter {
  @override
  Future<bool> get isConnected => Future.value(true);

  @override
  Stream<bool> get onConnectivityChanged => Stream<bool>.empty();
}
