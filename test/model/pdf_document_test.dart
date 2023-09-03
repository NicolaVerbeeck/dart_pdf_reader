import 'package:dart_pdf_reader/src/model/pdf_document.dart';
import 'package:dart_pdf_reader/src/model/pdf_document_catalog.dart';
import 'package:dart_pdf_reader/src/model/pdf_types.dart';
import 'package:dart_pdf_reader/src/parser/object_resolver.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockObjectResolver extends Mock implements ObjectResolver {}

void main() {
  group('PDFDocument', () {
    test('Test get catalog', () async {
      final dict = PDFDictionary({
        const PDFName('Root'): PDFDictionary({
          const PDFName('Type'): const PDFName('Catalog'),
        }),
      });
      final objectResolver = _MockObjectResolver();
      when(() => objectResolver
              .resolve<PDFDictionary>(dict[const PDFName('Root')]))
          .thenAnswer(
              (_) async => dict[const PDFName('Root')] as PDFDictionary);

      final sut = PDFDocument(
        mainTrailer: dict,
        objectResolver: objectResolver,
      );

      expect(await sut.catalog, isA<PDFDocumentCatalog>());
    });
  });
}
