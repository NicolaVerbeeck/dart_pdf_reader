import 'dart:convert';

import 'package:dart_pdf_reader/dart_pdf_reader.dart';
import 'package:test/test.dart';

void main() {
  group('String to pdf tests', () {
    group('Test literal strings', () {
      test('Test simple string', () {
        expect(PDFLiteralString(utf8.encode('Hello')).asPDFString(), '(Hello)');
      });
      test('Test empty string', () {
        expect(PDFLiteralString(utf8.encode('')).asPDFString(), '()');
      });
      test('Test string with escapes', () {
        expect(PDFLiteralString(utf8.encode('\r\n\t\b\f()\\')).asPDFString(),
            '(\\r\\n\\t\\b\\f\\(\\)\\\\)');
      });
    });
    group('Test hex strings', () {
      test('Test simple string', () {
        expect(
            PDFHexString(utf8.encode('Hello')).asPDFString(), '<48656c6c6f>');
      });
      test('Test empty string', () {
        expect(PDFHexString(utf8.encode('')).asPDFString(), '<>');
      });
      test('Test string with escapes', () {
        expect(PDFHexString(utf8.encode('\r\n\t\b\f()\\')).asPDFString(),
            '<0d0a09080c28295c>');
      });
    });
  });
}
