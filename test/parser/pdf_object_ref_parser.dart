part of 'pdf_object_parser_test.dart';

void objectRefParserTests() {
  group('Object ref parser tests', () {
    test('Test normal', () async {
      expect(await createParserFromString('12 22 R').parse(),
          const PDFObjectReference(objectId: 12, generationNumber: 22));
    });
    test('Test ending with comment', () async {
      expect(await createParserFromString('12 22 R%comment').parse(),
          const PDFObjectReference(objectId: 12, generationNumber: 22));
    });
  });
}
