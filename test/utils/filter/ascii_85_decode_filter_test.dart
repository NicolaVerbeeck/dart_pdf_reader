import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_pdf_reader/src/model/pdf_types.dart';
import 'package:dart_pdf_reader/src/utils/filter/stream_filter.dart';
import 'package:test/test.dart';

void main() {
  group('Filter tests', () {
    group('ASCII85DecodeFilter tests', () {
      test('Decoding test', () {
        final decoded = StreamFilter(const PDFName('ASCII85Decode')).decode(
          File('test/resources/ASCII85.bin').readAsBytesSync(),
          null,
          const PDFDictionary({}),
        );
        final decodedString = utf8.decode(decoded);
        const expected =
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec ac malesuada tellus. Quisque a arcu semper, tristique nibh eu, convallis lacus. Donec neque justo, condimentum sed molestie ac, mollis eu nibh. Vivamus pellentesque condimentum fringilla. Nullam euismod ac risus a semper. Etiam hendrerit scelerisque sapien tristique varius.';
        expect(decodedString, expected);
      });

      test('Decoding with zero bytes test', () {
        final decoded = StreamFilter(const PDFName('ASCII85Decode')).decode(
          Uint8List.fromList(utf8.encode('z9Q+r_D#')),
          null,
          const PDFDictionary({}),
        );
        expect(decoded, [0, 0, 0, 0, 76, 111, 114, 101, 109]);
      });

      test('Decoding single character', () {
        final decoded = StreamFilter(const PDFName('ASCII85Decode')).decode(
          Uint8List.fromList(utf8.encode('5l')),
          null,
          const PDFDictionary({}),
        );
        expect(decoded, utf8.encode('A'));
      });
      test('Decoding two characters', () {
        final decoded = StreamFilter(const PDFName('ASCII85Decode')).decode(
          Uint8List.fromList(utf8.encode('5sb')),
          null,
          const PDFDictionary({}),
        );
        expect(decoded, utf8.encode('AB'));
      });
      test('Decoding three characters', () {
        final decoded = StreamFilter(const PDFName('ASCII85Decode')).decode(
          Uint8List.fromList(utf8.encode('5sdp')),
          null,
          const PDFDictionary({}),
        );
        expect(decoded, utf8.encode('ABC'));
      });
    });
  });
}
