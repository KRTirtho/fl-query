import 'package:flutter/material.dart';
import 'package:json_view/json_view.dart' hide JsonConfig;

class ExplorerView extends StatefulWidget {
  final String title;
  final Object data;
  final VoidCallback? onClose;
  const ExplorerView({
    super.key,
    required this.title,
    required this.data,
    this.onClose,
  });

  @override
  State<ExplorerView> createState() => _ExplorerViewState();
}

class _ExplorerViewState extends State<ExplorerView> {
  @override
  Widget build(BuildContext context) {
    return Card(
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose,
                ),
                Text(widget.title),
              ],
            ),
            const Divider(),
            Expanded(
              child: JsonView(json: widget.data),
            ),
          ],
        ));
  }
}
