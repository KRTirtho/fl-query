import 'package:meta/meta.dart';

abstract class Subscribable<TListener extends Function> {
  @protected
  List<TListener> listeners;
  Subscribable() : listeners = [];

  void Function() subscribe([TListener? listener]) {
    listener ??= (() => null) as TListener;

    listeners.add(listener);

    onSubscribe();

    return () {
      listeners = listeners.where((x) => x != listener).toList();
      onUnsubscribe();
    };
  }

  bool hasListeners() {
    return listeners.isNotEmpty;
  }

  @protected
  void onSubscribe() {}

  @protected
  void onUnsubscribe() {}
}
