import 'package:dart_pdf_reader/dart_pdf_reader.dart';
import 'package:dart_pdf_reader/src/utils/filter/stream_filter.dart';
import 'package:test/test.dart';

void main() {
  group('Filter tests', () {
    test('Unknown filter test', () {
      expect(() => StreamFilter(const PDFName('ABC')),
          throwsA(isA<UnimplementedError>()));
    });
  });
}
