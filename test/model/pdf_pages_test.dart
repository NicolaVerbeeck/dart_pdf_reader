import 'package:dart_pdf_reader/src/model/pdf_document.dart';
import 'package:dart_pdf_reader/src/model/pdf_page.dart';
import 'package:dart_pdf_reader/src/model/pdf_types.dart';
import 'package:dart_pdf_reader/src/parser/object_resolver.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockPDFDocument extends Mock implements PDFDocument {}

class _MockObjectResolver extends Mock implements ObjectResolver {}

class _MockPDFPageNode extends Mock implements PDFPageObjectNode {}

void main() {
  group('PDFPages tests', () {
    test('Test get flat', () {
      final page1 = _MockPDFPageNode();
      final page2 = _MockPDFPageNode();

      final root = PDFPageTreeNode(
        _MockPDFDocument(),
        null,
        _MockObjectResolver(),
        const PDFDictionary({}),
        [page1, page2],
        2,
      );
      final sut = PDFPages(root);
      expect(sut.getPageAtIndex(0), page1);
      expect(sut.getPageAtIndex(1), page2);
      expect(() => sut.getPageAtIndex(2), throwsA(isA<Exception>()));
    });
    test('Test get nested', () {
      final page1 = _MockPDFPageNode();
      final page2 = _MockPDFPageNode();
      final page3 = _MockPDFPageNode();
      final page4 = _MockPDFPageNode();

      final child1 = PDFPageTreeNode(
        _MockPDFDocument(),
        null,
        _MockObjectResolver(),
        const PDFDictionary({}),
        [page1, page2],
        2,
      );
      final child2 = PDFPageTreeNode(
        _MockPDFDocument(),
        null,
        _MockObjectResolver(),
        const PDFDictionary({}),
        [page3, page4],
        2,
      );

      final root = PDFPageTreeNode(
        _MockPDFDocument(),
        null,
        _MockObjectResolver(),
        const PDFDictionary({}),
        [child1, child2],
        4,
      );
      final sut = PDFPages(root);
      expect(sut.pageCount, 4);
      expect(sut.getPageAtIndex(0), page1);
      expect(sut.getPageAtIndex(1), page2);
      expect(sut.getPageAtIndex(2), page3);
      expect(sut.getPageAtIndex(3), page4);
      expect(() => sut.getPageAtIndex(4), throwsA(isA<Exception>()));
    });
  });
}
