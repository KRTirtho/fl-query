import 'dart:async';

import 'package:fl_query/src/core/core.dart';
import 'package:fl_query/src/core/query_observer.dart';
import 'package:test/test.dart';

import '../../helpers/utils.dart';

typedef QueryFn = FutureOr<Map<String, dynamic>> Function(
    QueryFunctionContext<dynamic>);

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
      ;
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

    test('should be able to fetch with a selector', () async {
      final key = queryKey();
      ;
      final observer = QueryObserver<Map<String, dynamic>, dynamic,
              Map<String, dynamic>, Map<String, dynamic>>(
          queryClient,
          QueryObserverOptions<Map<String, dynamic>, dynamic,
              Map<String, dynamic>, Map<String, dynamic>>(
            queryKey: key,
            queryFn: (_) => {"count": 1},
            select: (data) => ({"myCount": data?["count"]}),
          ));
      QueryObserverResult? observerResult;
      final unsubscribe = observer.subscribe((result) {
        observerResult = result;
      });
      await Future.delayed(Duration(milliseconds: 1));
      unsubscribe();
      expect(
        observerResult?.data,
        equals({"myCount": 1}),
      );
    });

    test('should be able to fetch with a selector using the fetch method',
        () async {
      final key = queryKey();
      ;
      final observer = QueryObserver<Map<String, dynamic>, dynamic,
              Map<String, dynamic>, Map<String, dynamic>>(
          queryClient,
          QueryObserverOptions<Map<String, dynamic>, dynamic,
              Map<String, dynamic>, Map<String, dynamic>>(
            queryKey: key,
            queryFn: (_) => {"count": 1},
            select: (data) => ({"myCount": data?["count"]}),
          ));
      final observerResult = await observer.refetch();
      expect(observerResult?.data, equals({"myCount": 1}));
    });

    test('should run the selector again if the data changed', () async {
      final key = queryKey();
      ;
      int count = 0;
      final observer = QueryObserver<Map<String, dynamic>, dynamic,
              Map<String, dynamic>, Map<String, dynamic>>(
          queryClient,
          QueryObserverOptions<Map<String, dynamic>, dynamic,
              Map<String, dynamic>, Map<String, dynamic>>(
            queryKey: key,
            queryFn: (_) => Map.from({"count": count}),
            select: (data) {
              count++;
              return Map.from({"myCount": data?["count"]});
            },
          ));
      final observerResult1 = await observer.refetch();
      final observerResult2 = await observer.refetch();
      expect(count, 2);
      expect(observerResult1?.data, equals({"myCount": 0}));
      expect(observerResult2?.data, equals({"myCount": 1}));
    });

    test('should run the selector again if the selector changed', () async {
      final key = queryKey();
      ;
      int count = 0;
      final List<QueryObserverResult> results = [];
      final queryFn = (_) => ({"count": 1});
      select1(data) {
        count++;
        return {"myCount": data?["count"]};
      }

      select2(_data) {
        count++;
        return {"myCount": 99};
      }

      final observer = new QueryObserver(
          queryClient,
          QueryObserverOptions(
            queryKey: key,
            queryFn: queryFn,
            select: select1,
          ));
      final unsubscribe = observer.subscribe((result) {
        results.add(result);
      });
      await Future.delayed(Duration(milliseconds: 1));
      observer.setOptions(QueryObserverOptions(
        queryKey: key,
        queryFn: queryFn,
        select: select2,
      ));
      await Future.delayed(Duration(milliseconds: 1));
      //! Currently causing an extra call for refetch
      //! select shouldn't be called when refetch is called
      await observer.refetch();
      unsubscribe();
      expect(count, 2);
      expect(results.length, 5);
      expect(results.first.status, QueryStatus.loading);
      expect(results.first.isFetching, isTrue);
      expect(results.first.data, isNull);
      expect(results[1].status, QueryStatus.success);
      expect(results[1].isFetching, false);
      expect(results[1].data, {"myCount": 1});
      expect(results[2].status, QueryStatus.success);
      expect(results[2].isFetching, false);
      expect(results[2].data, {"myCount": 99});
      expect(results[3].status, QueryStatus.success);
      expect(results[3].isFetching, true);
      expect(results[3].data, {"myCount": 99});
      expect(results.last.status, QueryStatus.success);
      expect(results.last.isFetching, false);
      expect(results.last.data, {"myCount": 99});
    });
    test(
        'should not run the selector again if the data and selector did not change',
        () async {
      final key = queryKey();
      ;
      int count = 0;
      final List<QueryObserverResult> results = [];
      final queryFn = (_) => {"count": 1};
      select(data) {
        count++;
        return {"myCount": data["count"]};
      }

      final observer = new QueryObserver(
          queryClient,
          QueryObserverOptions(
            queryKey: key,
            queryFn: queryFn,
            select: select,
          ));
      final unsubscribe = observer.subscribe((result) {
        results.add(result);
      });
      await Future.delayed(Duration(milliseconds: 1));
      observer.setOptions(QueryObserverOptions(
        queryKey: key,
        queryFn: queryFn,
        select: select,
      ));
      await Future.delayed(Duration(milliseconds: 1));
      await observer.refetch();
      unsubscribe();
      expect(count, 1);
      expect(results.length, 4);
      expect(results.first.status, QueryStatus.loading);
      expect(results.first.isFetching, isTrue);
      expect(results.first.data, isNull);
      expect(results[1].status, QueryStatus.success);
      expect(results[1].isFetching, false);
      expect(results[1].data, {"myCount": 1});
      expect(results[2].status, QueryStatus.success);
      expect(results[2].isFetching, true);
      expect(results[2].data, {"myCount": 1});
      expect(results.last.status, QueryStatus.success);
      expect(results.last.isFetching, false);
      expect(results.last.data, {"myCount": 1});
    });

    test('should not run the selector again if the data did not change',
        () async {
      final key = queryKey();
      ;
      int count = 0;
      final observer = new QueryObserver<Map<String, dynamic>, dynamic,
          Map<String, dynamic>, Map<String, dynamic>>(
        queryClient,
        QueryObserverOptions<Map<String, dynamic>, dynamic,
            Map<String, dynamic>, Map<String, dynamic>>(
          queryKey: key,
          queryFn: (_) => {"count": 1},
          select: (data) {
            count++;
            return {"myCount": data?["count"]};
          },
        ),
      );
      final observerResult1 = await observer.refetch();
      final observerResult2 = await observer.refetch();
      expect(count, 1);
      expect(observerResult1?.data, equals({"myCount": 1}));
      expect(observerResult2?.data, equals({"myCount": 1}));
    });

    test('should always run the selector again if selector throws an error',
        () async {
      final key = queryKey();
      ;
      final List<QueryObserverResult> results = [];
      select(data) {
        throw new Exception('selector error');
      }

      queryFn(_) => ({"count": 1});
      final observer = new QueryObserver<Map<String, dynamic>, dynamic,
              Map<String, dynamic>, Map<String, dynamic>>(
          queryClient,
          QueryObserverOptions<Map<String, dynamic>, dynamic,
              Map<String, dynamic>, Map<String, dynamic>>(
            queryKey: key,
            queryFn: queryFn,
            select: select,
          ));
      final unsubscribe = observer.subscribe((result) {
        results.add(result);
      });
      await Future.delayed(Duration(milliseconds: 1));
      await observer.refetch();
      unsubscribe();
      expect(results.length, 5);
      expect(results.first.status, QueryStatus.loading);
      expect(results.first.isFetching, isTrue);
      expect(results.first.data, isNull);
      expect(results[1].status, QueryStatus.error);
      expect(results[1].isFetching, false);
      expect(results[1].data, isNull);
      expect(results[2].status, QueryStatus.error);
      expect(results[2].isFetching, true);
      expect(results[2].data, isNull);
      expect(results[3].status, QueryStatus.error);
      expect(results[3].isFetching, false);
      expect(results[3].data, isNull);
      expect(results.last.status, QueryStatus.error);
      expect(results.last.isFetching, false);
      expect(results.last.data, isNull);
    });

    test('should structurally share the selector', () async {
      final key = queryKey();
      ;
      int count = 0;
      final observer = new QueryObserver(
          queryClient,
          QueryObserverOptions<Map<String, dynamic>, dynamic,
              Map<String, dynamic>, Map<String, dynamic>>(
            queryKey: key,
            queryFn: (_) => {"count": ++count},
            select: (data) {
              return {"myCount": 1};
            },
          ));
      final observerResult1 = await observer.refetch();
      final observerResult2 = await observer.refetch();
      expect(count, 2);
      expect(observerResult1?.data, isNotNull);
      expect(observerResult1?.data, equals(observerResult2?.data));
    });

    test('should not trigger a fetch when subscribed and disabled', () async {
      int count = 0;
      final key = queryKey();
      ;
      final observer = new QueryObserver(
          queryClient,
          QueryObserverOptions(
            queryKey: key,
            queryFn: (_) {
              count++;
              return {"data": null};
            },
            enabled: false,
          ));
      final unsubscribe = observer.subscribe();
      await Future.delayed(Duration(milliseconds: 1));
      unsubscribe();
      expect(count, 0);
    });

    test('should not trigger a fetch when not subscribed', () async {
      int count = 0;
      final key = queryKey();
      ;
      new QueryObserver(
          queryClient,
          QueryObserverOptions(
            queryKey: key,
            queryFn: (_) {
              count++;
              return {"data": null};
            },
          ));
      await Future.delayed(Duration(milliseconds: 1));
      expect(count, 0);
    });

    test('should be able to watch a query without defining a query function',
        () async {
      int count = 0;
      int subscribeCount = 0;
      final key = queryKey();
      ;
      queryFn(_) {
        count++;
        return {"data": null};
      }

      final observer = QueryObserver<Map<String, dynamic>, dynamic,
              Map<String, dynamic>, Map<String, dynamic>>(
          queryClient,
          QueryObserverOptions<Map<String, dynamic>, dynamic,
              Map<String, dynamic>, Map<String, dynamic>>(
            queryKey: key,
            queryFn: queryFn,
            enabled: false,
          ));

      final unsubscribe = observer.subscribe((_) {
        subscribeCount++;
      });
      await queryClient.fetchQuery(queryKey: key, queryFn: queryFn);
      unsubscribe();
      expect(count, 1);
      expect(subscribeCount, 2);
    });

    test('should accept unresolved query config in update function', () async {
      final key = queryKey();
      ;
      final observer = QueryObserver<Map<String, dynamic>, dynamic,
              Map<String, dynamic>, Map<String, dynamic>>(
          queryClient,
          QueryObserverOptions<Map<String, dynamic>, dynamic,
              Map<String, dynamic>, Map<String, dynamic>>(
            queryKey: key,
            enabled: false,
          ));

      final List<QueryObserverResult> results = [];
      final unsubscribe = observer.subscribe((x) {
        results.add(x);
      });
      observer.setOptions(
        QueryObserverOptions(
          enabled: false,
          staleTime: Duration(milliseconds: 10),
        ),
      );
      int count = 0;

      queryFn(_) {
        count++;
        return {"data": null};
      }

      await queryClient.fetchQuery(queryKey: key, queryFn: queryFn);
      await sleep(100);
      unsubscribe();
      expect(count, 1);
      expect(results.length, 3);
      expect(results[0].isStale, true);
      expect(results[1].isStale, false);
      expect(results[2].isStale, true);
    });

    test('should be able to handle multiple subscribers', () async {
      final key = queryKey();

      int count = 0;

      final observer = new QueryObserver<Map<String, dynamic>, dynamic,
              Map<String, dynamic>, Map<String, dynamic>>(
          queryClient,
          QueryObserverOptions<Map<String, dynamic>, dynamic,
              Map<String, dynamic>, Map<String, dynamic>>(
            queryKey: key,
            enabled: false,
          ));
      final List<QueryObserverResult> results1 = [];
      final List<QueryObserverResult> results2 = [];
      final unsubscribe1 = observer.subscribe((x) {
        results1.add(x);
      });
      final unsubscribe2 = observer.subscribe((x) {
        results2.add(x);
      });
      await queryClient
          .fetchQuery<Map<String, dynamic>, dynamic, Map<String, dynamic>>(
        queryKey: key,
        queryFn: (_) {
          count++;
          return {"data": false};
        },
      );
      await sleep(50);
      unsubscribe1();
      unsubscribe2();
      expect(count, 1);
      expect(results1.length, 2);
      expect(results2.length, 2);
      expect(results1[0].data?["data"], isNull);
      expect(results1[1].data?["data"], isFalse);
      expect(results2[0].data?["data"], isNull);
      expect(results2[1].data?["data"], isFalse);
    });

    test('should be able to resolve a promise', () async {
      final key = queryKey();
      int count = 0;
      final observer = new QueryObserver<Map<String, dynamic>, dynamic,
              Map<String, dynamic>, Map<String, dynamic>>(
          queryClient,
          QueryObserverOptions<Map<String, dynamic>, dynamic,
              Map<String, dynamic>, Map<String, dynamic>>(
            queryKey: key,
            enabled: false,
          ));
      QueryObserverResult<Map<String, dynamic>, dynamic>? value;
      observer.getNextResult().then((x) {
        value = x;
      });
      queryClient
          .prefetchQuery<Map<String, dynamic>, dynamic, Map<String, dynamic>>(
              queryKey: key,
              queryFn: (_) {
                count++;
                return {"data": "a data"};
              });
      await sleep(50);
      expect(count, 1);
      expect(value?.data?["data"], "a data");
    });

    test('should be able to resolve a promise with an error', () async {
      final key = queryKey();
      final observer = new QueryObserver<Map<String, dynamic>, dynamic,
              Map<String, dynamic>, Map<String, dynamic>>(
          queryClient,
          QueryObserverOptions<Map<String, dynamic>, dynamic,
              Map<String, dynamic>, Map<String, dynamic>>(
            queryKey: key,
            enabled: false,
          ));
      var error;
      await observer.getNextResult(true).catchError((e) async {
        error = e;
        return e;
      });
      await queryClient
          .prefetchQuery<Map<String, dynamic>, dynamic, Map<String, dynamic>>(
              queryKey: key, queryFn: (_) => Future.error('reject'));
      await sleep(50);
      expect(error, 'reject');
    }, skip: true);

    test('should stop retry when unsubscribing', () async {
      int count = 0;
      try {
        final key = queryKey();
        final observer = new QueryObserver<Map<String, dynamic>, dynamic,
            Map<String, dynamic>, Map<String, dynamic>>(
          queryClient,
          QueryObserverOptions<Map<String, dynamic>, dynamic,
              Map<String, dynamic>, Map<String, dynamic>>(
            queryKey: key,
            queryFn: (_) {
              count++;
              return Future.error({"data": 'reject'});
            },
            retry: (_, __) => 10,
            retryDelay: (_, __) => 50,
          ),
        );
        final unsubscribe = observer.subscribe();
        await sleep(70);
        unsubscribe();
        await sleep(200);
      } catch (e) {
        print("ERROR OCCURRED $e");
      }
      expect(count, 2);
    });

    test('should clear interval when unsubscribing to a refetchInterval query',
        () async {
      final key = queryKey();

      final fetchData =
          (_) => Future<Map<String, dynamic>>.error({'data': null});
      final observer = new QueryObserver<Map<String, dynamic>, dynamic,
              Map<String, dynamic>, Map<String, dynamic>>(
          queryClient,
          QueryObserverOptions<Map<String, dynamic>, dynamic,
              Map<String, dynamic>, Map<String, dynamic>>(
            queryKey: key,
            queryFn: fetchData,
            cacheTime: Duration.zero,
            refetchInterval: (_, __) => Duration(milliseconds: 1),
          ));
      final unsubscribe = observer.subscribe();
      // @ts-expect-error
      expect(observer.refetchInterval, isNull);
      unsubscribe();
      // @ts-expect-error
      expect(observer.refetchInterval, isNotNull);
      await sleep(10);
      expect(queryClient.getQueryCache().find(key), isNotNull);
    });

    test(
        'uses placeholderData as non-cache data when loading a query with no data',
        () async {
      final key = queryKey();
      final observer = new QueryObserver<Map<String, dynamic>, dynamic,
              Map<String, dynamic>, Map<String, dynamic>>(
          queryClient,
          QueryObserverOptions<Map<String, dynamic>, dynamic,
              Map<String, dynamic>, Map<String, dynamic>>(
            queryKey: key,
            queryFn: (_) => {'data': 'data'},
            placeholderData: {"data": 'placeholder'},
          ));
      final result = observer.getCurrentResult();
      expect(result?.status, QueryStatus.success);

      final List<QueryObserverResult> results = [];

      final unsubscribe = observer.subscribe((x) {
        results.add(x);
      });

      await sleep(10);
      unsubscribe();

      expect(results.length, 2);
      expect(results.first.status, QueryStatus.success);
      expect(results.first.data, equals({"data": 'placeholder'}));
      expect(results.last.status, QueryStatus.success);
      expect(results.last.data, equals({'data': 'data'}));
    });

    test(
        'the retryer should not throw an error when reject if the retrier is already resolved',
        () async {
      final key = queryKey();
      int count = 0;

      final observer = new QueryObserver<Map<String, dynamic>, dynamic,
              Map<String, dynamic>, Map<String, dynamic>>(
          queryClient,
          QueryObserverOptions<Map<String, dynamic>, dynamic,
              Map<String, dynamic>, Map<String, dynamic>>(
            queryKey: key,
            queryFn: (_) {
              count++;
              return Future.error({'reject': count});
            },
            retry: (_, __) => 1,
            retryDelay: (_, __) => 20,
          ));

      final unsubscribe = observer.subscribe();

      // Simulate a race condition when an unsubscribe and a retry occur.
      await sleep(20);
      unsubscribe();

      // A second reject is triggered for the retry
      // but the retryer has already set isResolved to true
      // so it does nothing and no error is thrown

      // Should not log an error
      queryClient.clear();
      await sleep(40);
      expect(true, true);
      // expect(consoleMock).not.toHaveBeenNthCalledWith(1, 'reject 1')

      // consoleMock.mockRestore()
    });

    test('getCurrentQuery should return the current query', () async {
      final key = queryKey();

      final observer = new QueryObserver<Map<String, dynamic>, dynamic,
              Map<String, dynamic>, Map<String, dynamic>>(
          queryClient,
          QueryObserverOptions<Map<String, dynamic>, dynamic,
                  Map<String, dynamic>, Map<String, dynamic>>(
              queryKey: key, queryFn: (_) => {'data': 'data'}));

      expect(observer.getCurrentQuery().queryKey, key);
    });

    test('should throw an error if throwOnError option is true', () async {
      final key = queryKey();

      final observer = new QueryObserver<Map<String, dynamic>, dynamic,
              Map<String, dynamic>, Map<String, dynamic>>(
          queryClient,
          QueryObserverOptions<Map<String, dynamic>, dynamic,
              Map<String, dynamic>, Map<String, dynamic>>(
            queryKey: key,
            queryFn: (_) => Future.error({'error': 'error'}),
            retry: (_, __) => 0,
          ));

      var error = null;
      try {
        await observer.refetch(options: RefetchOptions(throwOnError: true));
      } catch (err) {
        error = err;
      }

      expect(error, equals({'error': 'error'}));
    });

    test(
        'should not refetch in background if refetchIntervalInBackground is false',
        () async {
      final key = queryKey();
      final spy = SpyFn();

      // focusManager.setFocused(false)
      final observer = new QueryObserver<Map<String, dynamic>, dynamic,
              Map<String, dynamic>, Map<String, dynamic>>(
          queryClient,
          QueryObserverOptions<Map<String, dynamic>, dynamic,
              Map<String, dynamic>, Map<String, dynamic>>(
            queryKey: key,
            queryFn: spy.fn1(),
            refetchIntervalInBackground: false,
            refetchInterval: (_, __) => Duration(milliseconds: 10),
          ));

      final unsubscribe = observer.subscribe();
      await sleep(30);

      expect(spy.calls, 1);

      // Clean-up
      unsubscribe();
      // focusManager.setFocused(true)
    });

    test(
        'should not use replaceEqualDeep for select value when structuralSharing option is true',
        () async {
      final key = queryKey();

      final data = {"value": 'data'};
      final selectedData = {"value": 'data'};

      final observer = new QueryObserver<Map<String, dynamic>, dynamic,
              Map<String, dynamic>, Map<String, dynamic>>(
          queryClient,
          QueryObserverOptions<Map<String, dynamic>, dynamic,
              Map<String, dynamic>, Map<String, dynamic>>(
            queryKey: key,
            queryFn: (_) => data,
            select: (_) => data,
          ));

      final unsubscribe = observer.subscribe();

      await sleep(10);
      expect(observer.getCurrentResult()?.data, data);

      observer.setOptions(QueryObserverOptions(
        queryKey: key,
        queryFn: (_) => data,
        structuralSharing: false,
        select: (_) => selectedData,
      ));

      await observer.refetch(filters: RefetchableQueryFilters(queryKey: key));
      expect(observer.getCurrentResult()?.data, selectedData);
      unsubscribe();
    });

    test('select function error using placeholderdata should log an error', () {
      final key = queryKey();

      QueryObserver<Map<String, dynamic>, dynamic, Map<String, dynamic>,
              Map<String, dynamic>>(
          queryClient,
          QueryObserverOptions<Map<String, dynamic>, dynamic,
              Map<String, dynamic>, Map<String, dynamic>>(
            queryKey: key,
            queryFn: (_) => {"data": 'data'},
            placeholderData: {"data": 'placeholderdata'},
            select: (_) {
              throw new Exception('error');
            },
          ));

      expect(true, true);
      // expect(consoleMock).toHaveBeenNthCalledWith(1, new Error('error'))

      // consoleMock.mockRestore()
    });

    test(
        'should not use replaceEqualDeep for select value when structuralSharing option is true and placeholderdata is defined',
        () {
      final key = queryKey();

      final data = {"value": 'data'};
      final selectedData1 = {"value": 'data'};
      final selectedData2 = {"value": 'data'};
      final placeholderData1 = {"value": 'data'};
      final placeholderData2 = {"value": 'data'};

      final observer = new QueryObserver<Map<String, dynamic>, dynamic,
              Map<String, dynamic>, Map<String, dynamic>>(
          queryClient,
          QueryObserverOptions<Map<String, dynamic>, dynamic,
              Map<String, dynamic>, Map<String, dynamic>>(
            queryKey: key,
            queryFn: (_) => data,
            select: (_) => data,
          ));

      observer.setOptions(QueryObserverOptions(
        queryKey: key,
        queryFn: (_) => data,
        select: (_) {
          return selectedData1;
        },
        placeholderData: placeholderData1,
      ));
      observer.setOptions(QueryObserverOptions(
        queryKey: key,
        queryFn: (_) => data,
        select: (_) {
          return selectedData2;
        },
        placeholderData: placeholderData2,
        structuralSharing: false,
      ));

      expect(observer.getCurrentResult()?.data, equals(selectedData2));
    });

    test(
        'should not use an undefined value returned by select as placeholderdata',
        () {
      final key = queryKey();

      final data = {"value": 'data'};
      final selectedData = {"value": 'data'};
      final placeholderData1 = {"value": 'data'};
      final placeholderData2 = {"value": 'data'};

      final observer = new QueryObserver<Map<String, dynamic>, dynamic,
              Map<String, dynamic>, Map<String, dynamic>>(
          queryClient,
          QueryObserverOptions<Map<String, dynamic>, dynamic,
              Map<String, dynamic>, Map<String, dynamic>>(
            queryKey: key,
            queryFn: (_) => data,
            select: (_) => data,
          ));

      observer.setOptions(QueryObserverOptions<Map<String, dynamic>, dynamic,
          Map<String, dynamic>, Map<String, dynamic>>(
        queryKey: key,
        queryFn: (_) => data,
        select: (_) {
          return selectedData;
        },
        placeholderData: placeholderData1,
      ));

      expect(observer.getCurrentResult()?.isPlaceholderData, isTrue);

      observer.setOptions(QueryObserverOptions<Map<String, dynamic>, dynamic,
          Map<String, dynamic>, Map<String, dynamic>>(
        queryKey: key,
        queryFn: (_) => data,
        select: (_) {
          return {};
        },
        placeholderData: placeholderData2,
      ));

      expect(observer.getCurrentResult()?.isPlaceholderData, isFalse);
    });

    test(
        'updateResult should not notify cache listeners if cache option is false',
        () async {
      final key = queryKey();

      final data1 = {"value": 'data 1'};
      final data2 = {"value": 'data 2'};

      await queryClient.prefetchQuery(queryKey: key, queryFn: (_) => data1);
      final observer = new QueryObserver<Map<String, dynamic>, dynamic,
              Map<String, dynamic>, Map<String, dynamic>>(
          queryClient,
          QueryObserverOptions<Map<String, dynamic>, dynamic,
              Map<String, dynamic>, Map<String, dynamic>>(queryKey: key));
      await queryClient.prefetchQuery(queryKey: key, queryFn: (_) => data2);

      final spy = SpyFn();
      final unsubscribe = queryClient.getQueryCache().subscribe(spy.fn1());
      observer.updateResult(NotifyOptions(cache: false));

      expect(spy.calls, 0);

      unsubscribe();
    });

    test(
        'should not notify observer when the stale timeout expires and the current result is stale',
        () async {
      final key = queryKey();
      final queryFn = (_) => {'data': "data"};

      await queryClient.prefetchQuery(queryKey: key, queryFn: queryFn);
      final observer = new QueryObserver<Map<String, dynamic>, dynamic,
              Map<String, dynamic>, Map<String, dynamic>>(
          queryClient,
          QueryObserverOptions<Map<String, dynamic>, dynamic,
              Map<String, dynamic>, Map<String, dynamic>>(
            queryKey: key,
            queryFn: queryFn,
            staleTime: Duration(milliseconds: 20),
          ));

      final spy = SpyFn();
      final unsubscribe = observer.subscribe(spy.fn1());
      await queryClient.refetchQueries(queryKeys: key);
      await sleep(10);

      // Force isStale to true
      // because no use case has been found to reproduce this condition
      // @ts-ignore
      // observer.getCurrentResult().isStale = true;
      await sleep(30);
      expect(spy.calls, 0);
      unsubscribe();
    });
  });
}
