import 'dart:io';

import 'package:dart_pdf_reader/src/model/pdf_types.dart';
import 'package:dart_pdf_reader/src/utils/filter/stream_filter.dart';
import 'package:test/test.dart';

void main() {
  group('Filter tests', () {
    group('FlateDecodeFilter tests', () {
      test('Should decode a flate encoded stream', () {
        final decoded = StreamFilter(const PDFName('FlateDecode')).decode(
          File('test/resources/flate.bin').readAsBytesSync(),
          null,
          const PDFDictionary({}),
        );
        expect(decoded,
            File('test/resources/flate_decoded.bin').readAsBytesSync());
      });
      test('Should decode a flate encoded stream with predictor', () {
        final decoded = StreamFilter(const PDFName('FlateDecode')).decode(
          File('test/resources/flate_predictor.bin').readAsBytesSync(),
          PDFDictionary({
            const PDFName('Predictor'): const PDFNumber(12),
            const PDFName('Columns'): const PDFNumber(3),
          }),
          const PDFDictionary({}),
        );
        expect(
            decoded,
            File('test/resources/flate_predictor_decoded.bin')
                .readAsBytesSync());
      });
    });
  });
}
