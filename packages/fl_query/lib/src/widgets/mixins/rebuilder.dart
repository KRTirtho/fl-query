import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Guarantees that the [setState] method is called only if the widget is
/// mounted and not in the middle of a frame. If it is in the middle of a frame,
/// it will wait for the end of the frame and then call [setState]. Which ensures
/// updates are not lost/skipped.
///
/// Shamelessly copied from [StackOverflow](https://stackoverflow.com/a/64702218/13292290)
///
/// Thanks to [dev-aggarwal](https://stackoverflow.com/users/7061265/dev-aggarwal)
mixin SafeRebuild<T extends StatefulWidget> on State<T> {
  Future<void> rebuild([_]) async {
    if (!mounted) return;

    // if there's a current frame,
    if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.idle) {
      // wait for the end of that frame.
      await SchedulerBinding.instance.endOfFrame;
      if (!mounted) return;
    }

    setState(() {});
  }
}
