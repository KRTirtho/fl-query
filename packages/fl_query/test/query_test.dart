import 'dart:math';

import 'package:fl_query/src/models/query_job.dart';
import 'package:fl_query/src/query.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockQueryJob extends Mock implements QueryJob {}

void main() {
  // for testing query without external data
  late Query query;
  late QueryJob queryJob;
  setUp(() {
    queryJob = MockQueryJob();
    when(() => queryJob.queryKey).thenReturn("test");
    when(() => queryJob.task("test", null))
        .thenAnswer((_) => (_, __) => "test");
    query = Query.fromOptions(
      queryJob,
      externalData: null,
    );
  });

  group("Query Test", () {
    test("default values", () {
      expect(query.enabled, isTrue);
      expect(query.refetchCount, 0);
      expect(query.retries, 3);
      expect(query.retryAttempts, 0);
      expect(query.fetched, isFalse);
      expect(query.retryDelay, Duration(milliseconds: 200));
      expect(query.status, QueryStatus.loading);
      expect(query.isStale, isFalse);
      expect(query.isIdle, isFalse);
      expect(query.isInactive, isTrue);
      expect(query.isLoading, isTrue);
      expect(query.isSuccess, isFalse);
      expect(query.hasError, isFalse);
      expect(query.hasData, isFalse);
    });

    test("calling fetch for the first time runs the _execute method", () async {
      final data = await query.fetch();

      expect(data, "test");
      expect(query.fetched, isTrue);
      verify(() => queryJob.task("test", null)).called(1);
    });

    test(
        "calling fetch twice or more should return same data where _execute gets called once",
        () async {
      final data1 = await query.fetch();
      final data2 = await query.fetch();

      await query.fetch();
      await query.fetch();
      expect(data1, data2);
      verify(() => queryJob.task("test", null)).called(1);
    });

    test('calling refetch should return new data', () async {
      reset(queryJob);
      when(() => queryJob.queryKey).thenReturn("test-1");
      when(() => queryJob.task("test-1", null)).thenAnswer((_) => (_, __) {
            return Future.value(Random().nextInt(100).toString());
          });
      final data = await query.fetch();
      await Future.delayed(Duration(milliseconds: 100));
      final refetchData = await query.refetch();

      expect(data, isNot(equals(refetchData)));
      verify(() => queryJob.task("test-1", null)).called(2);
    });
  });
}
