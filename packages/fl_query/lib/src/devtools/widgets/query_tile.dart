import 'package:flutter/material.dart';

class QueryTile extends StatelessWidget {
  final String title;
  final bool isLoading;
  final bool hasError;
  final VoidCallback? onTap;
  const QueryTile({
    super.key,
    required this.title,
    required this.isLoading,
    required this.hasError,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: AnimatedSwitcher(
        duration: const Duration(milliseconds: 100),
        child: isLoading
            ? const CircularProgressIndicator()
            : hasError
                ? Tooltip(
                    message: "'$title' has Errors",
                    child: const Icon(
                      Icons.error,
                      color: Colors.red,
                    ),
                  )
                : Tooltip(
                    message: "'$title' has fetched/mutated data successfully",
                    child: const Icon(
                      Icons.check,
                      color: Colors.green,
                    ),
                  ),
      ),
      title: Text(title),
    );
  }
}
