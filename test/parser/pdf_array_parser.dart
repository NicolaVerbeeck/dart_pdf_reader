part of 'pdf_object_parser_test.dart';

void arrayParserTests() {
  group('Array parser tests', () {
    test('Test normal', () async {
      expect(await createParserFromString('[1 2 3]').parse(),
          const PDFArray([PDFNumber(1), PDFNumber(2), PDFNumber(3)]));
    });
    test('Test mixed', () async {
      expect(
          await createParserFromString('[1 (2) 3]').parse(),
          PDFArray([
            const PDFNumber(1),
            PDFLiteralString(Uint8List.fromList(utf8.encode('2'))),
            const PDFNumber(3)
          ]));
    });
    test('Test mixed nested', () async {
      expect(
          await createParserFromString('[1 (2) [3 4]]').parse(),
          PDFArray([
            const PDFNumber(1),
            PDFLiteralString(Uint8List.fromList(utf8.encode('2'))),
            const PDFArray([PDFNumber(3), PDFNumber(4)])
          ]));
    });
    test('Test mixed newlines', () async {
      expect(
          await createParserFromString('[1\n(2)\n3\n]').parse(),
          PDFArray([
            const PDFNumber(1),
            PDFLiteralString(Uint8List.fromList(utf8.encode('2'))),
            const PDFNumber(3)
          ]));
    });
    test('Test mixed newlines with comments', () async {
      expect(
          await createParserFromString('[1%cmd\n(2)\n%cmd\n3\n]').parse(),
          PDFArray([
            const PDFNumber(1),
            PDFLiteralString(Uint8List.fromList(utf8.encode('2'))),
            const PDFNumber(3)
          ]));
    });
  });
}
