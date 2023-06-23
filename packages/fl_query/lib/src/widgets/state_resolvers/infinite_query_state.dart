import 'package:flutter/widgets.dart';

class InfiniteQueryStateResolverProvider extends InheritedWidget {
  final Widget Function(List errors)? error;
  final Widget Function()? loading;
  final Widget Function()? offline;

  InfiniteQueryStateResolverProvider({
    this.error,
    this.loading,
    this.offline,
    required super.child,
  }) : assert(
          error != null || loading != null || offline != null,
          'Why are you using `InfiniteQueryStateResolverProvider` with no resolver?\n'
          'You should provide at least one resolver.',
        );

  static InfiniteQueryStateResolverProvider? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<
        InfiniteQueryStateResolverProvider>();
  }

  static InfiniteQueryStateResolverProvider of(BuildContext context) {
    final provider = maybeOf(context);
    assert(
      provider != null,
      'You are trying to access a `InfiniteQueryStateResolverProvider` outside of its scope.\n'
      'You should wrap your widget tree with `InfiniteQueryStateResolverProvider`.',
    );
    return provider!;
  }

  @override
  bool updateShouldNotify(InfiniteQueryStateResolverProvider oldWidget) {
    return error != oldWidget.error ||
        loading != oldWidget.loading ||
        offline != oldWidget.offline;
  }
}
