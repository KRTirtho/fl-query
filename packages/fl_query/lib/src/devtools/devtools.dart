import 'package:fl_query/src/devtools/widgets/devtools_root.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FlQueryDevtools extends StatefulWidget {
  final Widget? child;
  const FlQueryDevtools({
    super.key,
    this.child,
  });

  @override
  State<FlQueryDevtools> createState() => _FlQueryDevtoolsState();
}

class _FlQueryDevtoolsState extends State<FlQueryDevtools> {
  bool _showDevtools = false;

  @override
  Widget build(BuildContext context) {
    if (kReleaseMode) {
      return SizedBox.shrink(child: widget.child);
    }

    return Navigator(
      onPopPage: (route, result) {
        return true;
      },
      pages: [
        MaterialPage(
          child: Scaffold(
            body: Stack(
              children: [
                if (widget.child != null) widget.child!,
                if (_showDevtools) ...[
                  Positioned(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _showDevtools = false;
                        });
                      },
                      child: SizedBox.expand(
                        child: ColoredBox(
                          color: Colors.black38,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.7,
                        width: double.infinity,
                        margin: const EdgeInsets.all(8.0),
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: DevtoolsRoot(
                          onClose: () {
                            setState(() {
                              _showDevtools = false;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ]
              ],
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.startFloat,
            floatingActionButton: AnimatedScale(
              duration: const Duration(milliseconds: 100),
              scale: _showDevtools ? 0 : 1,
              child: FloatingActionButton.extended(
                onPressed: () {
                  setState(() {
                    _showDevtools = !_showDevtools;
                  });
                },
                label: Text("Fl-Query Devtools"),
                icon: Icon(Icons.search_rounded),
              ),
            ),
          ),
        ),
      ],
    );
  }
}