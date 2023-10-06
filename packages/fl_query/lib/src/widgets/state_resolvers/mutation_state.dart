import 'package:flutter/widgets.dart';

class MutationStateResolverProvider extends InheritedWidget {
  final Widget Function(dynamic error)? error;
  final Widget Function()? loading;
  final Widget Function()? offline;
  final Widget Function()? mutating;

  MutationStateResolverProvider({
    this.error,
    this.loading,
    this.offline,
    this.mutating,
    required super.child,
  }) : assert(
          error != null || loading != null || offline != null,
          'Why are you using `MutationStateResolverProvider` with no resolver?\n'
          'You should provide at least one resolver.',
        );

  static MutationStateResolverProvider? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<MutationStateResolverProvider>();
  }

  static MutationStateResolverProvider of(BuildContext context) {
    final provider = maybeOf(context);
    assert(
      provider != null,
      'You are trying to access a `MutationStateResolverProvider` outside of its scope.\n'
      'You should wrap your widget tree with `MutationStateResolverProvider`.',
    );
    return provider!;
  }

  @override
  bool updateShouldNotify(MutationStateResolverProvider oldWidget) {
    return error != oldWidget.error ||
        loading != oldWidget.loading ||
        offline != oldWidget.offline ||
        mutating != oldWidget.mutating;
  }
}
