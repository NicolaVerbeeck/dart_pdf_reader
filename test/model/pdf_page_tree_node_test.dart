import 'package:dart_pdf_reader/src/model/pdf_document.dart';
import 'package:dart_pdf_reader/src/model/pdf_page.dart';
import 'package:dart_pdf_reader/src/model/pdf_types.dart';
import 'package:dart_pdf_reader/src/parser/object_resolver.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockPDFDocument extends Mock implements PDFDocument {}

class _MockObjectResolver extends Mock implements ObjectResolver {}

class _MockPDFPageNode extends Mock implements PDFPageNode {}

void main() {
  group('PDFPageTreeNode tests', () {
    test('Test length', () {
      final sut = PDFPageTreeNode(
        _MockPDFDocument(),
        null,
        _MockObjectResolver(),
        const PDFDictionary({}),
        [_MockPDFPageNode(), _MockPDFPageNode()],
        2,
      );
      expect(sut.length, 2);
    });
    test('Test length empty', () {
      final sut = PDFPageTreeNode(
        _MockPDFDocument(),
        null,
        _MockObjectResolver(),
        const PDFDictionary({}),
        [],
        0,
      );
      expect(sut.length, 0);
    });
    test('Test get index', () {
      final sut = PDFPageTreeNode(
        _MockPDFDocument(),
        null,
        _MockObjectResolver(),
        const PDFDictionary({}),
        [_MockPDFPageNode(), _MockPDFPageNode()],
        2,
      );
      expect(sut[0], isNotNull);
      expect(sut[1], isNotNull);
    });
  });
}
