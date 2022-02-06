import 'package:fl_query/src/exceptions/exceptions_next.dart'
    show UnknownException;

export 'package:fl_query/src/exceptions/exceptions_next.dart';

import 'package:fl_query/src/exceptions/network.dart'
    if (dart.library.io) 'package:fl_query/src/exceptions/network_io.dart'
    as network;

export 'package:fl_query/src/exceptions/network.dart'
    if (dart.library.io) 'package:fl_query/src/exceptions/network_io.dart';

LinkException translateFailure(dynamic failure, StackTrace trace) {
  if (failure is LinkException) {
    return failure;
  }
  return network.translateFailure(failure) ?? UnknownException(failure, trace);
}
