import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

ValueChanged<dynamic> useUpdater() {
  final state = useState(false);
  final isMounted = useIsMounted();
  return ([_]) {
    if (isMounted()) state.value = !state.value;
  };
}
