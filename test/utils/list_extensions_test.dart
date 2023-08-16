import 'dart:typed_data';

import 'package:dart_pdf_reader/src/utils/list_extensions.dart';
import 'package:test/test.dart';

void main() {
  group('List Extensions', () {
    test('Test Uint8List list to Uint8List', () {
      final uint8List = Uint8List.fromList([1, 2, 3, 4, 5]);
      final list = uint8List.asUint8List();
      expect(list, isA<Uint8List>());
      expect(list, [1, 2, 3, 4, 5]);
    });
    test('Test int list to Uint8List', () {
      final list = <int>[1, 2, 3, 4, 5];
      final uint8List = list.asUint8List();
      expect(uint8List, isA<Uint8List>());
      expect(uint8List, [1, 2, 3, 4, 5]);
    });
  });
}
