import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

// a flutter hook that can force update the ui
//
// Usage:
// final forceUpdate = useForceUpdate();
// forceUpdate();

useForceUpdate() {
  final state = useState(false);
  return () => state.value = !state.value;
}
