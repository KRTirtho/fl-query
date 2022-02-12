import 'package:meta/meta.dart';

abstract class Subscribable<TListener extends Function> {
  @protected
  List<TListener> listeners;
  Subscribable() : listeners = [];

  void Function() subscribe(TListener? listener) {
    var callback = listener ?? (() => null);

    listeners.add(callback as TListener);

    onSubscribe();

    return () {
      listeners = listeners.where((x) => x != callback).toList();
      onUnsubscribe();
    };
  }

  bool hasListeners() {
    return listeners.isNotEmpty;
  }

  @protected
  void onSubscribe();

  @protected
  void onUnsubscribe();
}
