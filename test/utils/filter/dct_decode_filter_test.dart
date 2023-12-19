import 'dart:typed_data';

import 'package:dart_pdf_reader/dart_pdf_reader.dart';
import 'package:dart_pdf_reader/src/utils/filter/stream_filter.dart';
import 'package:test/test.dart';

void main() {
  group('Filter tests', () {
    test('DCTDecode test', () {
      final decoded = StreamFilter(const PDFName('DCTDecode')).decode(
        Uint8List.fromList([0, 1, 2, 3, 4, 5]),
        null,
        const PDFDictionary({}),
      );
      expect(decoded, [0, 1, 2, 3, 4, 5]);
    });
    test('JPXDecode test', () {
      final decoded = StreamFilter(const PDFName('JPXDecode')).decode(
        Uint8List.fromList([0, 1, 2, 3, 4, 5]),
        null,
        const PDFDictionary({}),
      );
      expect(decoded, [0, 1, 2, 3, 4, 5]);
    });
  });
}
