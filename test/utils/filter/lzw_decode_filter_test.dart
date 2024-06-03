import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_pdf_reader/src/model/pdf_types.dart';
import 'package:dart_pdf_reader/src/utils/filter/stream_filter.dart';
import 'package:test/test.dart';

void main() {
  group('Filter tests', () {
    group('LZWDecodeFilter tests', () {
      test('Decoding test', () {
        final decoded = StreamFilter(const PDFName('LZWDecode')).decode(
          Uint8List.fromList(
              [0x80, 0x0B, 0x60, 0x50, 0x22, 0x0C, 0x0C, 0x85, 0x01]),
          null,
          const PDFDictionary({}),
        );
        final decodedString = utf8.decode(decoded);
        const expected = '-----A---B';
        expect(decodedString, expected);
      });
    });
  });
}
