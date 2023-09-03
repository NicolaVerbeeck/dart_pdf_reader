import 'package:dart_pdf_reader/src/utils/cache/lru_map.dart';
import 'package:test/test.dart';

void main() {
  group('LRUMap tests', () {
    test('Test set items removes old items', () {
      final cache = LRUMap<String, int>(3);
      cache['a'] = 1;
      cache['b'] = 2;
      cache['c'] = 3;
      cache['d'] = 4;
      expect(cache['a'], null);
      expect(cache['b'], 2);
      expect(cache['c'], 3);
      expect(cache['d'], 4);
    });
    test('Test access items moves them to the front', () {
      final cache = LRUMap<String, int>(3);
      cache['a'] = 1;
      cache['b'] = 2;
      cache['c'] = 3;
      cache['a'];
      cache['d'] = 4;
      expect(cache['a'], 1);
      expect(cache['b'], null);
      expect(cache['c'], 3);
      expect(cache['d'], 4);
    });
    test('Test remove items', () {
      final cache = LRUMap<String, int>(3);
      cache['a'] = 1;
      cache['b'] = 2;
      cache['c'] = 3;
      cache.remove('b');
      cache['d'] = 4;
      expect(cache['a'], 1);
      expect(cache['b'], null);
      expect(cache['c'], 3);
      expect(cache['d'], 4);
    });
    test('Test getOrPut items', () {
      final cache = LRUMap<String, int>(3);
      cache['a'] = 1;
      cache['b'] = 2;
      cache['c'] = 3;
      cache.getOrPut('b', () => 4);
      cache.getOrPut('d', () => 5);
      expect(cache['a'], 1);
      expect(cache['b'], 2);
      expect(cache['c'], 3);
      expect(cache['d'], 5);
    });
    test('Test overwrite items removes old items', () {
      final cache = LRUMap<String, int>(3);
      cache['a'] = 1;
      cache['b'] = 2;
      cache['c'] = 3;
      cache['a'] = 5;
      cache['d'] = 4;
      expect(cache['a'], 5);
      expect(cache['b'], null);
      expect(cache['c'], 3);
      expect(cache['d'], 4);
    });
  });
}
