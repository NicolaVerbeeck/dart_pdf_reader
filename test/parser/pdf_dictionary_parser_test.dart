part of 'pdf_object_parser_test.dart';

void dictionaryParserTests() {
  group('Dictionary parser tests', () {
    test('Test empty dictionary', () async {
      expect(await createParserFromString('<<>>').parse(),
          const PDFDictionary({}));
    });
    test('Test dictionary not keyed by name', () async {
      expect(createParserFromString('<< Name /Value >>').parse(),
          throwsA(isA<ParseException>()));
    });
    test('Test dictionary invalid ending', () async {
      expect(createParserFromString('<< /Name /Value >a').parse(),
          throwsA(isA<ParseException>()));
    });
    test('Test dictionary missing value', () async {
      expect(createParserFromString('<< /Name >>').parse(),
          throwsA(isA<ParseException>()));
    });
    test('Test dictionary name to name', () async {
      expect(await createParserFromString('<</Key\r\n\r/Value>>').parse(),
          PDFDictionary({const PDFName('Key'): const PDFName('Value')}));
    });
    test('Test nested dictionary', () async {
      expect(
          await createParserFromString('<</Key<</Key2/Value>>>>').parse(),
          PDFDictionary({
            const PDFName('Key'):
                PDFDictionary({const PDFName('Key2'): const PDFName('Value')})
          }));
    });
    test('Test nested dictionary complex', () async {
      expect(
          await createParserFromString('<</Key<</Key2 [1 2 3]>>>>').parse(),
          PDFDictionary({
            const PDFName('Key'): PDFDictionary({
              const PDFName('Key2'): const PDFArray([
                PDFNumber(1),
                PDFNumber(2),
                PDFNumber(3),
              ])
            })
          }));
    });
  });
}
