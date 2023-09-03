import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_pdf_reader/src/model/pdf_document.dart';
import 'package:dart_pdf_reader/src/model/pdf_document_catalog.dart';
import 'package:dart_pdf_reader/src/model/pdf_outline.dart';
import 'package:dart_pdf_reader/src/model/pdf_types.dart';
import 'package:dart_pdf_reader/src/parser/object_resolver.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockPDFDocument extends Mock implements PDFDocument {}

class _MockObjectResolver extends Mock implements ObjectResolver {}

void main() {
  group('PDFDocumentCatalog tests', () {
    group('Metadata tests', () {
      late ObjectResolver mockResolver;

      setUp(() {
        mockResolver = _MockObjectResolver();
        when(() => mockResolver.resolve<PDFStringLike>(captureAny()))
            .thenAnswer((invocation) async =>
                invocation.positionalArguments[0] as PDFStringLike?);
      });

      test('Test read version', () async {
        final mockDocument = _MockPDFDocument();

        final dict = PDFDictionary({
          const PDFName('Version'):
              PDFLiteralString(Uint8List.fromList(utf8.encode('1.4'))),
        });
        final catalog = PDFDocumentCatalog(mockDocument, dict, mockResolver);
        expect(await catalog.getVersion(), '1.4');
      });

      test('Test read language', () async {
        final mockDocument = _MockPDFDocument();

        final dict = PDFDictionary({
          const PDFName('Lang'):
              PDFLiteralString(Uint8List.fromList(utf8.encode('en-GB'))),
        });
        final catalog = PDFDocumentCatalog(mockDocument, dict, mockResolver);
        expect(await catalog.getLanguage(), 'en-GB');
      });
    });
    group('Outline tests', () {
      late ObjectResolver mockResolver;
      setUp(() {
        mockResolver = _MockObjectResolver();
        when(() => mockResolver.resolve<PDFDictionary>(captureAny()))
            .thenAnswer((invocation) async =>
                invocation.positionalArguments[0] as PDFDictionary?);
      });
      test('Test read outlines', () async {
        final dict = PDFDictionary({
          const PDFName('Outlines'): PDFDictionary({
            const PDFName('First'): PDFDictionary({
              const PDFName('Title'): PDFLiteralString(
                  Uint8List.fromList(utf8.encode('First Title'))),
              const PDFName('A'): PDFDictionary({
                const PDFName('D'):
                    const PDFArray([PDFNumber(1), PDFNumber(2), PDFNumber(3)]),
                const PDFName('S'): const PDFName('GoTo'),
              }),
            }),
          }),
        });

        final mockDocument = _MockPDFDocument();
        final catalog = PDFDocumentCatalog(mockDocument, dict, mockResolver);
        final outlines = await catalog.getOutlines();
        expect(outlines, isNotNull);
        expect(outlines![0].title, 'First Title');
        expect(outlines[0].action, isA<PDFOutlineGoToAction>());
        final dest = (outlines[0].action as PDFOutlineGoToAction).destination;
        expect(dest, isA<PDFArray>());
        dest as PDFArray;
        expect(dest[0], const PDFNumber(1));
        expect(dest[1], const PDFNumber(2));
        expect(dest[2], const PDFNumber(3));
      });
    });
    group('Pages tests', () {
      late ObjectResolver mockResolver;
      setUp(() {
        mockResolver = _MockObjectResolver();
        when(() => mockResolver.resolve<PDFDictionary>(captureAny()))
            .thenAnswer((invocation) async =>
                invocation.positionalArguments[0] as PDFDictionary?);
        when(() => mockResolver.resolve<PDFArray>(captureAny())).thenAnswer(
            (invocation) async =>
                invocation.positionalArguments[0] as PDFArray?);
        when(() => mockResolver.resolve<PDFNumber>(captureAny())).thenAnswer(
            (invocation) async =>
                invocation.positionalArguments[0] as PDFNumber?);
      });
      test('Test read pages', () async {
        final dict = PDFDictionary({
          const PDFName('Pages'): PDFDictionary({
            const PDFName('Count'): const PDFNumber(2),
            const PDFName('Kids'): PDFArray([
              PDFDictionary({
                const PDFName('Type'): const PDFName('Pages'),
                const PDFName('Count'): const PDFNumber(1),
                const PDFName('Kids'): PDFArray([
                  PDFDictionary({
                    const PDFName('Type'): const PDFName('Page'),
                  }),
                ]),
              }),
              PDFDictionary({
                const PDFName('Type'): const PDFName('Page'),
              }),
            ]),
          }),
        });

        final mockDocument = _MockPDFDocument();
        final catalog = PDFDocumentCatalog(mockDocument, dict, mockResolver);
        final pages = await catalog.getPages();
        expect(pages, isNotNull);
      });
    });
  });
}
