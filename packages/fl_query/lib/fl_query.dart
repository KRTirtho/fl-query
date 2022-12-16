library fl_query;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart'
    if (dart.library.html) 'package:hive_flutter/src/stub/path.dart'
    as path_helper;

export 'src/infinite_query.dart';
export 'src/infinite_query_builder.dart';
export 'src/query.dart';
export 'src/query_bowl.dart';
export 'src/query_builder.dart';
export 'src/mutation.dart';
export 'src/mutation_builder.dart';
export 'src/always_online_connectivity.dart';
export 'src/models/infinite_query_job.dart';
export 'src/models/query_job.dart';
export 'src/models/mutation_job.dart';
import 'package:path_provider/path_provider.dart';
export 'src/utils.dart' show isShallowEqual, getVariable;

late final kFlQueryBoxKey;

/// `cacheKey`: An unique key to identify the cache of fl_query for this
///  application
///
/// `cacheSubDirectory`: The sub directory to store the cache file
///
/// `encryptionKey`: The encryption key to encrypt the cache of fl_query
///
/// If not provided then the cache won't be encrypted.
/// The encryption key must be a list of 32 integers
///
/// You can use [Random.secure().nextBytes(32)] to generate a random encryption key.
/// And store that key in a secure storage like
/// [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage)
///  for securely storing the encryption key when your application is closed.
Future<void> initializeFlQuery({
  required String cacheKey,
  List<int>? encryptionKey,
  String? cacheSubDirectory,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) return;

  final appDir = await getApplicationDocumentsDirectory();
  Hive.init(
    path_helper.join(appDir.path, cacheSubDirectory),
    backendPreference: HiveStorageBackendPreference.webWorker,
  );
  kFlQueryBoxKey = cacheKey + "-fl_query";
  await Hive.openLazyBox<String>(
    kFlQueryBoxKey,
    encryptionCipher:
        encryptionKey != null ? HiveAesCipher(encryptionKey) : null,
  );
}
