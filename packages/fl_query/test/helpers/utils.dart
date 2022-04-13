import 'package:fl_query/src/core/core.dart';
import 'package:uuid/uuid.dart';

Uuid uuid = Uuid();

QueryKey queryKey() {
  return QueryKey("query_${uuid.v4()}");
}

class SpyFn<T extends Function()> {
  int _calls = 0;
  late T _customFn;
  int get calls => _calls;
  T get customFn => _customFn;

  SpyFn();

  SpyFn.withFn(this._customFn);

  fn([Function()? cb]) {
    _calls++;
    return () => cb?.call();
  }

  fn1([Function()? cb]) {
    _calls++;
    return (p0) => cb?.call();
  }

  fn2([Function()? cb]) {
    _calls++;
    return (p0, p1) => cb?.call();
  }

  fn3([Function()? cb]) {
    _calls++;
    return (p0, p1, p2) => cb?.call();
  }

  fn4([Function()? cb]) {
    _calls++;
    return (p0, p1, p2, p3) => cb?.call();
  }

  fn5([Function()? cb]) {
    _calls++;
    return (p0, p1, p2, p3, p4) => cb?.call();
  }
}

Future<void> sleep(int ms) => Future.delayed(Duration(milliseconds: ms));
