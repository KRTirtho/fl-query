library fl_query;

import 'package:flutter/material.dart';

class FlQueryScope extends StatefulWidget {
  final Widget child;
  const FlQueryScope({required this.child, Key? key}) : super(key: key);

  @override
  State<FlQueryScope> createState() => _FlQueryScopeState();
}

class _FlQueryScopeState extends State<FlQueryScope> {
  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return widget.child;
  }
}
