import 'package:fl_query/src/core/core.dart';
import 'package:test/test.dart';

import '../../helpers/utils.dart';

void main() {
  group('QueryObserver', () {
    late QueryClient queryClient;

    setUp(() {
      queryClient = QueryClient();
      queryClient.mount();
    });

    tearDown(() {
      queryClient.clear();
    });

    test('should trigger a fetch when subscribed', () async {
      final key = queryKey();
      int calls = 0;
      queryFn(context) {
        calls++;
        return {"data": "data1"};
      }

      final observer = QueryObserver(
        queryClient,
        QueryObserverOptions(queryKey: key, queryFn: queryFn),
      );
      final unsubscribe = observer.subscribe();
      await Future.delayed(Duration(milliseconds: 1));
      unsubscribe();
      expect(calls, 1);
    });

    test('should notify when switching query', () async {
      final key1 = queryKey();
      final key2 = queryKey();
      final List<QueryObserverResult> results = [];
      final observer = QueryObserver(
        queryClient,
        QueryObserverOptions(
          queryKey: key1,
          queryFn: (_) => {"data": 1},
        ),
      );
      final unsubscribe = observer.subscribe((result) {
        results.add(result);
      });
      await Future.delayed(Duration(milliseconds: 1));
      observer.setOptions(
        QueryObserverOptions(queryKey: key2, queryFn: (_) => {"data": 2}),
      );
      await Future.delayed(Duration(milliseconds: 2));
      unsubscribe();
      expect(results.length, 4);
      expect(results[0].data, isNull);
      expect(results[0].status, QueryStatus.loading);
      expect(results[1].data, {"data": 1});
      expect(results[1].status, QueryStatus.success);
      expect(results[2].data, isNull);
      expect(results[2].status, QueryStatus.loading);
      expect(results[3].data, {"data": 2});
      expect(results[3].status, QueryStatus.success);
    });
  });
}
