import 'dart:io';

import 'package:fl_query_connectivity_plus_adapter/connection_checker.dart';

mixin ConnectionLookupMixin implements ConnectionLookup {
  @override
  Future<bool> doesConnectTo(String address) async {
    try {
      final result = await InternetAddress.lookup(address);
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static const _vpnNames = [
    'tun',
    'tap',
    'ppp',
    'pptp',
    'l2tp',
    'ipsec',
    'vpn',
    'wireguard',
    'openvpn',
    'softether',
    'proton',
    'strongswan',
    'cisco',
    'forticlient',
    'fortinet',
    'hideme',
    'hidemy',
    'hideman',
    'hidester',
    'lightway',
  ];

  @override
  Future<bool> isVpnActive() async {
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.any,
    );

    if (interfaces.isEmpty) {
      return false;
    }

    return interfaces.any(
      (interface) =>
          _vpnNames.any((name) => interface.name.toLowerCase().contains(name)),
    );
  }
}
