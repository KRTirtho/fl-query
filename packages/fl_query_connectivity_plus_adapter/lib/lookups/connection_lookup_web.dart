import 'dart:html';
import 'package:fl_query_connectivity_plus_adapter/connection_checker.dart';

mixin ConnectionLookupMixin implements ConnectionLookup {
  @override
  Future<bool> doesConnectTo(String address) async {
    try {
      final url = address.startsWith("http") || address.startsWith("/")
          ? address
          : "https://$address";
      final request = await HttpRequest.request(
        url,
        requestHeaders: {
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      );

      return (request.status ?? 0) < 400;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> isVpnActive() {
    return Future.value(false);
  }
}
