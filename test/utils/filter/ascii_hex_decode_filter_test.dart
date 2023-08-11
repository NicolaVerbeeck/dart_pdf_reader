import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_pdf_reader/dart_pdf_reader.dart';
import 'package:dart_pdf_reader/src/utils/filter/stream_filter.dart';
import 'package:test/test.dart';

void main() {
  group('Filter tests', () {
    group('ASCIIHexDecodeFilter tests', () {
      test('Decoding test', () {
        final decoded = StreamFilter(const PDFName('ASCIIHexDecode')).decode(
          File('test/resources/ASCIIHex.bin').readAsBytesSync(),
          null,
          const PDFDictionary({}),
        );
        final decodedString = utf8.decode(decoded);
        final expected =
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec ac malesuada tellus. Quisque a arcu semper, tristique nibh eu, convallis lacus. Donec neque justo, condimentum sed molestie ac, mollis eu nibh. Vivamus pellentesque condimentum fringilla. Nullam euismod ac risus a semper. Etiam hendrerit scelerisque sapien tristique varius.';
        expect(decodedString, expected);
      });

      test('Decoding illegal character test', () {
        expect(
            () => StreamFilter(const PDFName('ASCIIHexDecode')).decode(
                  Uint8List.fromList(utf8.encode('4c6f72656d20697073756d2eg>')),
                  null,
                  const PDFDictionary({}),
                ),
            throwsA(isA<ParseException>()));
      });

      test('Decoding skip whitespaces test', () {
        final decoded = StreamFilter(const PDFName('ASCIIHexDecode')).decode(
          Uint8List.fromList(
              utf8.encode('4c 6f 72 65 6d 20 69 70 73 75 6d 2e>')),
          null,
          const PDFDictionary({}),
        );
        final decodedString = utf8.decode(decoded);
        expect(decodedString, 'Lorem ipsum.');
      });
    });
  });
}
