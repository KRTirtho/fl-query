import 'package:flutter/widgets.dart';

class QueryStateResolverProvider extends InheritedWidget {
  final Widget Function(dynamic error)? error;
  final Widget Function()? loading;
  final Widget Function()? offline;

  QueryStateResolverProvider({
    this.error,
    this.loading,
    this.offline,
    required super.child,
  }) : assert(
          error != null || loading != null || offline != null,
          'Why are you using `QueryStateResolverProvider` with no resolver?\n'
          'You should provide at least one resolver.',
        );

  static QueryStateResolverProvider? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<QueryStateResolverProvider>();
  }

  static QueryStateResolverProvider of(BuildContext context) {
    final provider = maybeOf(context);
    assert(
      provider != null,
      'You are trying to access a `QueryStateResolverProvider` outside of its scope.\n'
      'You should wrap your widget tree with `QueryStateResolverProvider`.',
    );
    return provider!;
  }

  @override
  bool updateShouldNotify(QueryStateResolverProvider oldWidget) {
    return error != oldWidget.error ||
        loading != oldWidget.loading ||
        offline != oldWidget.offline;
  }
}
