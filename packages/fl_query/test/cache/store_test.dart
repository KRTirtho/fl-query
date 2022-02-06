import 'dart:io';

import 'package:fl_query/fl_query.dart';
import 'package:fl_query/src/utilities/helpers.dart';
import 'package:test/test.dart';

void main() {
  group('InMemoryStore', () {
    final data = {
      'id': {'key': 'value'},
      'id2': {'otherKey': false}
    };
    test('basic methods', () {
      final store = InMemoryStore();
      store.put('id', data['id']);
      expect(store.get('id'), equals(data['id']));

      store.delete('id');
      expect(store.data, equals({}));
    });
    test('bulk methods', () {
      final store = InMemoryStore();

      store.putAll(data);

      expect(store.data, equals(data));
      expect(store.toMap(), equals(data));

      store.reset();

      expect(data['id'], notNull); // no mutations
    });
  });

  group('HiveStore', () {
    final data = {
      'id': {'key': 'value'},
      'id2': {'otherKey': false}
    };
    final path = './test/cache/test_hive_boxes/';
    test('basic methods', () async {
      final store =
          await HiveStore.open(boxName: 'basic', path: path + 'basic');
      store.put('id', data['id']);
      expect(store.get('id'), equals(data['id']));

      store.delete('id');
      expect(store.toMap(), equals({}));

      await store.box.deleteFromDisk();
    });
    test('bulk methods', () async {
      final store = await HiveStore.open(boxName: 'bulk', path: path + 'bulk');

      store.putAll(data);
      expect(store.toMap(), equals(data));

      await store.reset();
      expect(store.toMap(), equals({}));

      expect(data['id'], notNull); // no mutations

      await store.box.deleteFromDisk();
    });

    test('box rereferencing', () async {
      final store = await HiveStore.open(path: path);
      store.putAll(data);

      expect(HiveStore().toMap(), equals(data));

      await store.box.deleteFromDisk();
    });

    tearDownAll(() async {
      await Directory(path).delete(recursive: true);
    });
  });
}
