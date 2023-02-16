import 'package:flutter/material.dart';
import 'package:state_notifier/state_notifier.dart';

typedef StateNotifierListenableBuilder<T> = Widget Function(
  BuildContext context,
  StateNotifier<T> value,
);

class StateNotifierListenable<T> extends StatefulWidget {
  final StateNotifier<T> notifier;
  final StateNotifierListenableBuilder<T> builder;
  const StateNotifierListenable({
    required this.notifier,
    required this.builder,
    super.key,
  });

  @override
  State<StateNotifierListenable<T>> createState() =>
      _StateNotifierListenableState<T>();
}

class _StateNotifierListenableState<T>
    extends State<StateNotifierListenable<T>> {
  VoidCallback? removeListener;

  void initialize() {
    removeListener = widget.notifier.addListener((_) {
      setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initialize();
    });
  }

  @override
  void dispose() {
    removeListener?.call();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant StateNotifierListenable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notifier != widget.notifier) {
      removeListener?.call();
      initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, widget.notifier);
  }
}
