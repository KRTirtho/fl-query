import 'dart:math';

import 'package:fl_query/src/models/query_job.dart';
import 'package:fl_query/src/query.dart';
import 'package:fl_query/src/query_bowl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'query_test.mocks.dart';

@GenerateMocks(
  [QueryBowl],
  customMocks: [
    MockSpec<QueryJob<Object, void>>(
      as: #MockQueryJobVoidObject,
      returnNullOnMissingStub: true,
    ),
  ],
)
void main() {
  // for testing query without external data
  late Query query;
  late MockQueryJobVoidObject queryJob;
  late MockQueryBowl queryBowl;
  setUp(() {
    queryJob = MockQueryJobVoidObject();
    queryBowl = MockQueryBowl();
    when(queryJob.queryKey).thenReturn("test");
    when(queryJob.task).thenAnswer(
      (_) =>
          (_, __) => Future.delayed(Duration(milliseconds: 300), () => "test"),
    );
    query = Query.fromOptions(
      queryJob,
      externalData: null,
      queryBowl: queryBowl,
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
      expect(query.status, QueryStatus.idle);
      expect(query.isStale, isFalse);
      expect(query.isIdle, true);
      expect(query.isInactive, isTrue);
      expect(query.isLoading, isFalse);
      expect(query.isSuccess, isFalse);
      expect(query.hasError, isFalse);
      expect(query.hasData, isFalse);
    });

    test("calling fetch for the first time runs the _execute method", () async {
      final data = await query.fetch();
      expect(data, "test");
      expect(query.fetched, isTrue);
      verify(queryJob.task).called(1);
    });

    test(
        "calling fetch twice or more should return same data where _execute gets called once",
        () async {
      final data1 = await query.fetch();
      final data2 = await query.fetch();

      await query.fetch();
      await query.fetch();
      expect(data1, data2);
      verify(queryJob.task).called(1);
    });

    test('calling refetch should return new data', () async {
      reset(queryJob);
      when(queryJob.queryKey).thenReturn("test");
      when(queryJob.task).thenAnswer(
        (_) => (_, __) => Future.value(Random().nextInt(100)),
      );
      query = Query.fromOptions(
        queryJob,
        externalData: null,
        queryBowl: queryBowl,
      );

      await Future.delayed(Duration(milliseconds: 100));
      await query.fetch().then((data) async {
        final refetchData = await query.refetch();
        expect(data, isNot(equals(refetchData)));
      });
    });

    test(
      "refetch should not run When another refetch is already running",
      () async {
        await query.fetch();
        await Future.delayed(Duration(milliseconds: 100));
        await Future.wait([
          query.refetch(),
          query.refetch(),
        ]);
        expect(query.refetchCount, 1);
      },
    );
    test(
      "failing task should be retried the amount of times passed as retries parameter",
      () async {
        reset(queryJob);
        when(queryJob.queryKey).thenReturn("test");
        when(queryJob.task).thenAnswer(
          (_) => (_, __) => Future.error("Error"),
        );
        query = Query.fromOptions(
          queryJob,
          externalData: null,
          queryBowl: queryBowl,
        );

        await query.fetch();

        expect(query.retryAttempts, 3);
        expect(query.isError, true);
      },
    );
    test(
      "onData listeners are called When new data is fetched and set",
      () async {
        int count = 0;
        query.onDataListeners.add((_) {
          count++;
        });
        await query.fetch();
        expect(count, 1);
      },
    );
    test(
      "onError listeners are called When any error occurs",
      () {},
    );
    test("query should become stale after defined amount time", () {});
    test(
      "query should refetch in interval When refetchInterval is specified",
      () {},
    );
    test(
      "query should revalidate When a new caller gets mounted",
      () {},
    );
    test(
      "query should not revalidate When there's no Internet Connectivity and a new caller gets mounted",
      () {},
    );
  });
}
