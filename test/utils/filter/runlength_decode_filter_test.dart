import 'dart:typed_data';

import 'package:dart_pdf_reader/src/model/pdf_types.dart';
import 'package:dart_pdf_reader/src/utils/filter/stream_filter.dart';
import 'package:test/test.dart';

void main() {
  group('Filter tests', () {
    group('RunLengthDecodeFilter tests', () {
      test('Should decode a runlength decode encoded stream', () {
        final inputData = BytesBuilder();
        // Single byte expansion
        inputData
          ..addByte(0x00)
          ..addByte(0xBE);

        // Multi byte expansion
        inputData
          ..addByte(0x7F)
          ..add(List.generate(128, (index) => index));

        // Repetition
        inputData
          ..addByte(0x81)
          ..addByte(0xBE);

        // Stop
        inputData
          ..addByte(0x80)
          ..addByte(0xED);

        // Expected results
        final expectedData = BytesBuilder();
        // Single byte expansion
        expectedData.addByte(0xBE);

        // Multi byte expansion
        expectedData.add(List.generate(128, (index) => index));

        // Repetition
        expectedData.add(List.generate(128, (index) => 0xBE));

        final decoded = StreamFilter(const PDFName('RunLengthDecode')).decode(
          inputData.toBytes(),
          null,
          const PDFDictionary({}),
        );
        expect(
          decoded,
          expectedData.toBytes(),
        );
      });
    });
  });
}
