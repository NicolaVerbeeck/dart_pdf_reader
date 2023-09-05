part of 'pdf_object_parser_test.dart';

void basicParserTests() {
  group('Basic parser tests', () {
    test('Test boolean', () async {
      expect(
          await createParserFromString('true').parse(), const PDFBoolean(true));
      expect(await createParserFromString('false').parse(),
          const PDFBoolean(false));
    });
    test('Test null', () async {
      expect(await createParserFromString('null').parse(), const PDFNull());
    });
    test('Test number', () async {
      expect(await createParserFromString('1').parse(), const PDFNumber(1));
      expect(await createParserFromString('2.0').parse(), const PDFNumber(2.0));
      expect(
          await createParserFromString('-3.0').parse(), const PDFNumber(-3.0));
      expect(
          await createParserFromString('+4.0').parse(), const PDFNumber(4.0));
      expect(await createParserFromString('+4.0920029').parse(),
          const PDFNumber(4.0920029));
      expect(await createParserFromString('-4.0920029').parse(),
          const PDFNumber(-4.0920029));
      expect(await createParserFromString('.0920029').parse(),
          const PDFNumber(.0920029));
      expect(() => createParserFromString('9.2a0dd').parse(),
          throwsA(isA<ParseException>()));
    });
    test('Test command', () async {
      expect(await createParserFromString('someCommand').parse(),
          const PDFCommand('someCommand'));
      expect(await createParserFromString('someCommand secondCommand').parse(),
          const PDFCommand('someCommand'));
      expect(await createParserFromString('someCommand% secondCommand').parse(),
          const PDFCommand('someCommand'));
    });
  });
}
