import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fl_query/src/utils.dart';
import 'package:flutter/widgets.dart';

abstract class BaseOperation<Data, Error> extends ChangeNotifier {
  /// The number of times the query should refetch in the time of error
  /// before giving up
  final int retries;
  final Duration retryDelay;

  // got from global options
  @protected
  Duration cacheTime;

  Connectivity _connectivity;

  // all properties
  Data? data;
  Error? error;

  /// total count of how many times the query retried to get a successful
  /// result
  int retryAttempts = 0;
  DateTime updatedAt;

  bool fetched = false;

  /// used for keeping track of query activity. If the are no mounts &
  /// the passed cached time is over than the query is removed from
  /// storage/cache
  Set<ValueKey<String>> _mounts = {};

  BaseOperation({
    required this.cacheTime,
    required this.retries,
    required this.retryDelay,
    this.data,
    Connectivity? connectivity,
  })  : updatedAt = DateTime.now(),
        _connectivity = connectivity ?? Connectivity();

  void mount(ValueKey<String> uKey) {
    _mounts.add(uKey);
  }

  void unmount(ValueKey<String> uKey) {
    if (_mounts.length == 1) {
      Future.delayed(cacheTime, () {
        _mounts.remove(uKey);
        // for letting know QueryBowl that this one's time has come for
        // getting crushed
        notifyListeners();
      });
    } else {
      _mounts.remove(uKey);
    }
  }

  Set<ValueKey<String>> get mounts => _mounts;

  /// checks if the application is connected to internet in any mean
  ///
  /// It's true when any one this is connected -
  /// - ethernet
  /// - mobile
  /// - wifi
  ///
  /// Deprecated: Use [isNetworkOnline] instead
  @deprecated
  Future<bool> isInternetConnected() async {
    return isNetworkOnline;
  }

  /// checks if the application is connected to internet in any mean
  ///
  /// It's true when any one this is connected -
  /// - ethernet
  /// - mobile
  /// - wifi
  Future<bool> get isNetworkOnline =>
      _connectivity.checkConnectivity().then((v) => isConnectedToInternet(v));

  bool get isInactive => mounts.isEmpty;
  bool get hasData => data != null;
  bool get hasError => error != null;
}
