import 'dart:convert';

import 'package:dart_pdf_reader/dart_pdf_reader.dart';
import 'package:dart_pdf_reader/src/utils/list_extensions.dart';
import 'package:test/test.dart';

void main() {
  group('String to pdf tests', () {
    group('Test literal strings', () {
      test('Test simple string', () {
        expect(
            PDFLiteralString(utf8.encode('Hello').asUint8List()).asPDFString(),
            '(Hello)');
      });
      test('Test empty string', () {
        expect(PDFLiteralString(utf8.encode('').asUint8List()).asPDFString(),
            '()');
      });
      test('Test string with escapes', () {
        expect(
            PDFLiteralString(utf8.encode('\r\n\t\b\f()\\').asUint8List())
                .asPDFString(),
            '(\\r\\n\\t\\b\\f\\(\\)\\\\)');
      });
    });
    group('Test hex strings', () {
      test('Test simple string', () {
        expect(PDFHexString(utf8.encode('Hello').asUint8List()).asPDFString(),
            '<48656c6c6f>');
      });
      test('Test empty string', () {
        expect(PDFHexString(utf8.encode('').asUint8List()).asPDFString(), '<>');
      });
      test('Test string with escapes', () {
        expect(
            PDFHexString(utf8.encode('\r\n\t\b\f()\\').asUint8List())
                .asPDFString(),
            '<0d0a09080c28295c>');
      });
    });
  });
}
