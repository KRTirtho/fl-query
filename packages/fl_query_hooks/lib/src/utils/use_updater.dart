import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

ValueChanged<dynamic> useUpdater() {
  final state = useState(false);
  final isMounted = useIsMounted();
  return ([_]) async {
    if (!isMounted()) return;

    // if there's a current frame,
    if (SchedulerBinding.instance.schedulerPhase != SchedulerPhase.idle) {
      // wait for the end of that frame.
      await SchedulerBinding.instance.endOfFrame;
      if (!isMounted()) return;
    }

    state.value = !state.value;
  };
}
