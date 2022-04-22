import 'dart:async';

import 'package:fl_query/src/core/online_manager.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import './online_manager_test.mocks.dart';

@GenerateMocks([InternetConnectionChecker])
void main() {
  group('OnlineManager', () {
    late OnlineManager onlineManagerTest;
    late StreamController<InternetConnectionStatus> statusController;
    late MockInternetConnectionChecker connectionChecker;
    setUp(() {
      statusController = StreamController<InternetConnectionStatus>.broadcast();
      statusController.add(InternetConnectionStatus.connected);
      connectionChecker = MockInternetConnectionChecker();
      when(connectionChecker.hasConnection)
          .thenAnswer((_) => Future.value(true));
      when(connectionChecker.hasListeners)
          .thenReturn(statusController.hasListener);
      when(connectionChecker.onStatusChange)
          .thenAnswer((_) => statusController.stream);
      onlineManagerTest = OnlineManager(connectionChecker);
    });

    tearDown(() {
      statusController.close();
    });

    test(
      'isOnline Should return true When InternetConnectionChecker.hasConnection is true',
      () async {
        bool online = await onlineManagerTest.isOnline();
        expect(online, isTrue);
      },
    );

    test(
      "setEventListener Should use _online property When setOnline sets _online = false",
      () async {
        int count = 0;

        setup(void Function(bool?) setOnline) {
          Timer(Duration(milliseconds: 20), () {
            count++;
            setOnline(false);
          });
          return () {};
        }

        onlineManagerTest.setEventListener(setup);
        await Future.delayed(Duration(milliseconds: 30));
        expect(count, equals(1));
        onlineManagerTest.isOnline().then((online) {
          expect(online, isFalse);
        });
      },
    );

    test(
      'setEventListener Should call previous remove handler When replacing an event listener',
      () {
        int cb1calls = 0;
        int cb2calls = 0;
        onlineManagerTest.setEventListener((_) => () => cb1calls++);
        onlineManagerTest.setEventListener((_) => () => cb2calls++);
        expect(cb1calls, equals(1));
        expect(cb2calls, equals(0));
      },
    );
    test(
      'Should replace default window listener When a new event listener is set',
      () {
        // Should set the default event listener with window event listeners
        final unsubscribe = onlineManagerTest.subscribe();
        verify(connectionChecker.onStatusChange.listen).called(1);
        // Should replace the window default event listener by a new one
        // and it should call window.removeEventListener twice
        onlineManagerTest.setEventListener((online) {
          return () => null;
        });
        expect(connectionChecker.hasListeners, isFalse);
        unsubscribe();
      },
    );

    test('Should cancel StreamSubscription When last listener unsubscribes',
        () {
      final unsubscribe1 = onlineManager.subscribe(() => null);
      final unsubscribe2 = onlineManager.subscribe(() => null);

      verify(connectionChecker.onStatusChange.listen).called(1);
      unsubscribe1();
      expect(connectionChecker.hasListeners, isTrue);
      unsubscribe2();
      expect(connectionChecker.hasListeners, isFalse);
    }, skip: true);

    test('should keep setup function even if last listener unsubscribes', () {
      int count = 0;
      onlineManager.setEventListener((_) => () => count++);

      final unsubscribe1 = onlineManagerTest.subscribe(() => null);
      expect(count, equals(1));
      unsubscribe1();

      final unsubscribe2 = onlineManager.subscribe(() => null);
      expect(count, equals(2));
      unsubscribe2();
    }, skip: true);
  });
}
