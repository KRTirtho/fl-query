import 'package:fl_query/src/core/notify_manager.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

class SpyNotifyManager extends NotifyManager {
  SpyNotifyManager() : super();

  int flushCall = 0;

  @override
  void flush() {
    super.flush();
    flushCall++;
  }
}

void main() {
  group("NotifyManager", () {
    test(
      "Should call _notifyFn in schedule When no callback is batched",
      () async {
        final NotifyManager notifyManager = NotifyManager();
        int called = 0;
        notifyManager.schedule(() => called++);
        await Future.delayed(Duration(milliseconds: 1));
        expect(called, equals(1));
      },
    );

    test(
      "Should call default _batchNotifyFn even When multiple level deep callbacks are registered",
      () async {
        final NotifyManager notifyManager = NotifyManager();
        int level1 = 0;
        int level2 = 0;
        int level3 = 0;
        callback() async {
          await Future.delayed(Duration(milliseconds: 20));
          level3++;
        }

        notifyManager.batch(() {
          notifyManager.batch(() {
            notifyManager.schedule(callback);
            level2++;
          });
          level1++;
        });
        await Future.delayed(Duration(milliseconds: 30));
        expect(level1, equals(1));
        expect(level2, equals(1));
        expect(level3, equals(1));
      },
      timeout: Timeout(Duration(minutes: 2)),
    );

    test("Should flush When Exception is thrown in a batched callback", () {
      final SpyNotifyManager notifyManager = SpyNotifyManager();
      try {
        notifyManager.batch(() {
          throw Exception("Damn an exception");
        });
      } catch (e) {}

      expect(notifyManager.flushCall, equals(1));
    });
  });
}
