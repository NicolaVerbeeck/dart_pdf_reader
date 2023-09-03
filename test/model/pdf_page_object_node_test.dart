import 'dart:math';

import 'package:dart_pdf_reader/src/model/pdf_document.dart';
import 'package:dart_pdf_reader/src/model/pdf_page.dart';
import 'package:dart_pdf_reader/src/model/pdf_types.dart';
import 'package:dart_pdf_reader/src/parser/object_resolver.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockPDFPageNode extends Mock implements PDFPageNode {}

class _MockPDFDocument extends Mock implements PDFDocument {}

class _MockObjectResolver extends Mock implements ObjectResolver {}

void main() {
  group('PDFPageObjectNode tests', () {
    test('Test get media box from parent', () {
      final parent = _MockPDFPageNode();
      final resolver = _MockObjectResolver();

      when(() => parent.getOrInherited<PDFArray>(const PDFName('MediaBox')))
          .thenAnswer((_) => const PDFArray([
                PDFNumber(0),
                PDFNumber(10),
                PDFNumber(120),
                PDFNumber(2000),
              ]));

      final sut = PDFPageObjectNode(
        _MockPDFDocument(),
        parent,
        resolver,
        const PDFDictionary({}),
      );

      final rect = sut.mediaBox;
      expect(rect, const Rectangle(0.0, 10.0, 120.0, 1990.0));
    });
    test('Test media box malformed', () {
      final sut = PDFPageObjectNode(
        _MockPDFDocument(),
        null,
        _MockObjectResolver(),
        PDFDictionary({
          const PDFName('MediaBox'): const PDFArray([
            PDFNumber(0),
            PDFNumber(10),
            PDFNumber(120),
          ]),
        }),
      );
      expect(() => sut.mediaBox, throwsArgumentError);
    });
    test('Test media box inverted', () {
      final sut = PDFPageObjectNode(
        _MockPDFDocument(),
        null,
        _MockObjectResolver(),
        PDFDictionary({
          const PDFName('MediaBox'): const PDFArray([
            PDFNumber(120),
            PDFNumber(2000),
            PDFNumber(0),
            PDFNumber(10),
          ]),
        }),
      );
      final rect = sut.mediaBox;
      expect(rect, const Rectangle(0.0, 10.0, 120.0, 1990.0));
    });
  });
}
