import 'package:fl_query/src/core/utils.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('core/utils', () {
    group('replaceEqualDeep', () {
      test(
          'Should return the previous value When the next value is an equal primitive',
          () {
        expect(replaceEqualDeep(1, 1), equals(1));
        expect(replaceEqualDeep('1', '1'), equals('1'));
        expect(replaceEqualDeep(true, true), true);
        expect(replaceEqualDeep(false, false), false);
        expect(replaceEqualDeep(null, null), null);
      });
      test(
          'Should return the next value When the previous value is a different value',
          () {
        expect(replaceEqualDeep(1, 0), equals(0));
        expect(replaceEqualDeep(1, 2), equals(2));
        expect(replaceEqualDeep('1', '2'), equals('2'));
        expect(replaceEqualDeep(true, false), equals(false));
        expect(replaceEqualDeep(false, true), equals(true));
      });

      test(
          'Should return the next value When the previous value is a different type',
          () {
        final array = [1];
        final object = {"a": "a"};
        expect(replaceEqualDeep(0, null), equals(null));
        expect(replaceEqualDeep(null, 0), equals(0));
        expect(replaceEqualDeep(2, null), equals(null));
        expect(replaceEqualDeep(null, 2), equals(2));
        expect(replaceEqualDeep({}, null), equals(null));
        expect(replaceEqualDeep([], null), equals(null));
        expect(replaceEqualDeep(array, object), equals(object));
        expect(replaceEqualDeep(object, array), equals(array));
      });

      test(
          'Should return the previous value When the next value is an equal array',
          () {
        final prev = [1, 2];
        final next = [1, 2];
        expect(replaceEqualDeep(prev, next), equals(prev));
      });

      test(
          'Should return a copy When the previous value is a different array subset',
          () {
        final prev = [1, 2];
        final next = [1, 2, 3];
        final result = replaceEqualDeep(prev, next);
        expect(result, equals(next));
        expect(result, isNot(equals(prev)));
      });

      test(
          'Should return the previous value When the next value is an equal empty array',
          () {
        final prev = [];
        final next = [];
        expect(replaceEqualDeep(prev, next), equals(prev));
      });

      test(
          'Should return the previous value When the next value is an equal empty object',
          () {
        final prev = {};
        final next = {};
        expect(replaceEqualDeep(prev, next), equals(prev));
      });

      test(
          'Should return the previous value When the next value is an equal object',
          () {
        final prev = {"a": 'a'};
        final next = {"a": 'a'};
        expect(replaceEqualDeep(prev, next), equals(prev));
      });

      test('Should replace different values in objects', () {
        final prev = {
          "a": {"b": 'b'},
          "c": 'c'
        };
        final next = {
          "a": {"b": 'b'},
          "c": 'd'
        };
        final result = replaceEqualDeep(prev, next);
        expect(result, equals(next));
        expect(result, isNot(prev));
        expect(result["a"], equals(prev["a"]));
        expect(result["c"], equals(next["c"]));
      });

      test('Should replace different values in arrays', () {
        final prev = [
          1,
          {"a": 'a'},
          {
            "b": {"b": 'b'}
          },
          [1]
        ];
        final next = [
          1,
          {"a": 'a'},
          {
            "b": {"b": 'c'}
          },
          [1]
        ];
        final result = replaceEqualDeep(prev, next);
        expect(result, equals(next));
        expect(result, isNot(prev));
        expect(result[0], prev[0]);
        expect(result[1], prev[1]);
        expect((result[2] as Map)["b"]["b"], (next[2] as Map)["b"]["b"]);
        expect(result[3], prev[3]);
      });

      test(
          'Should replace different values in arrays When the next value is a subset',
          () {
        final prev = [
          {"a": 'a'},
          {"b": 'b'},
          {"c": 'c'}
        ];
        final next = [
          {"a": 'a'},
          {"b": 'b'}
        ];
        final result = replaceEqualDeep(prev, next);
        expect(result, equals(next));
        expect(result, isNot(prev));
        expect(result[0], prev[0]);
        expect(result[1], prev[1]);
        expect(() => result[2], throwsRangeError);
      });

      test(
          'Should replace different values in arrays When the next value is a superset',
          () {
        final prev = [
          {"a": 'a'},
          {"b": 'b'}
        ];
        final next = [
          {"a": 'a'},
          {"b": 'b'},
          {"c": 'c'}
        ];
        final result = replaceEqualDeep(prev, next);
        expect(result, equals(next));
        expect(result[0], equals(prev[0]));
        expect(result[1], equals(prev[1]));
        expect(result[2], equals(next[2]));
      });

      test('Should copy objects which are not arrays or objects', () {
        final prev = [
          {"a": 'a'},
          {"b": 'b'},
          {"c": 'c'},
          1
        ];
        final next = [
          {"a": 'a'},
          Map(),
          {"c": 'c'},
          2
        ];
        final result = replaceEqualDeep(prev, next);
        expect(result[0], equals(prev[0]));
        expect(result[1], equals(next[1]));
        expect(result[2], equals(prev[2]));
        expect(result[3], equals(next[3]));
      });

      test('Should support equal objects which are not arrays or objects', () {
        final map = new Map();
        final prev = [
          map,
          [1]
        ];
        final next = [
          map,
          [1]
        ];
        final result = replaceEqualDeep(prev, next);
        expect(result, equals(prev));
      });

      test('Should support non equal objects which are not arrays or objects',
          () {
        final map1 = new Map();
        final map2 = new Map();
        final prev = [
          map1,
          [1]
        ];
        final next = [
          map2,
          [1]
        ];
        final result = replaceEqualDeep(prev, next);
        expect(result[0], equals(next[0]));
        expect(result[1], equals(prev[1]));
      });

      test('Should replace all parent objects if some nested value changes',
          () {
        final prev = {
          "todo": {
            "id": '1',
            "meta": {"createdAt": 0},
            "state": {"done": false},
          },
          "otherTodo": {
            "id": '2',
            "meta": {"createdAt": 0},
            "state": {"done": true},
          },
        };
        final next = {
          "todo": {
            "id": '1',
            "meta": {"createdAt": 0},
            "state": {"done": true},
          },
          "otherTodo": {
            "id": '2',
            "meta": {"createdAt": 0},
            "state": {"done": true},
          },
        };
        final result = replaceEqualDeep(prev, next);
        expect(result, equals(next));
        expect(result["todo"] == prev["todo"], isFalse);
        expect(result["todo"] == next["todo"], isFalse);
        expect(result["todo"]["id"], equals((next["todo"] as Map)["id"]));
        expect(result["todo"]["meta"], equals((prev["todo"] as Map)["meta"]));
        expect(
          result["todo"]["state"],
          equals((next["todo"] as Map)["state"]),
        );
        expect(
          result["todo"]["state"]["done"],
          (next["todo"] as Map)["state"]["done"],
        );
        expect(result["otherTodo"], prev["otherTodo"]);
      });

      test('Should replace all parent arrays if some nested value changes', () {
        final Map<String, List<Map>> prev = {
          "todos": [
            {
              "id": '1',
              "meta": {"createdAt": 0},
              "state": {"done": false}
            },
            {
              "id": '2',
              "meta": {"createdAt": 0},
              "state": {"done": true}
            },
          ],
        };
        final Map<String, List<Map>> next = {
          "todos": [
            {
              "id": '1',
              "meta": {"createdAt": 0},
              "state": {"done": true}
            },
            {
              "id": '2',
              "meta": {"createdAt": 0},
              "state": {"done": true}
            },
          ],
        };
        final result = replaceEqualDeep(prev, next);
        expect(result, equals(next));
        expect(result["todos"][0], isNot(equals(prev["todos"]?.first)));
        expect(
          result["todos"][0]?["id"],
          equals(next["todos"]?.first["id"]),
        );
        expect(
          result["todos"][0]?["meta"],
          equals(prev["todos"]?.first["meta"]),
        );
        expect(result["todos"][0]?["state"]["done"],
            next["todos"]?.first["state"]["done"]);
        expect(result["todos"][1], equals(prev["todos"]?[1]));
      });
    });

    group(
        'matchMutation',
        () => {
              // test('should return false if mutationKey options is undefined', () => {
              //   const filters = { mutationKey: 'key1' };
              //   const queryClient = new QueryClient();
              //   const mutation = new Mutation({
              //     mutationId: 1,
              //     mutationCache: queryClient.getMutationCache(),
              //     options: {},
              //   })
              //   expect(matchMutation(filters, mutation)).toBeFalsy()
              // })
            });
  });
}
