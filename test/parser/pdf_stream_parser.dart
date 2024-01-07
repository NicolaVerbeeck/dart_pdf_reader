part of 'pdf_object_parser_test.dart';

class _MockIndirectObjectParser extends Mock implements IndirectObjectParser {}

void streamParserTests() {
  group('Stream parser tests', () {
    test('Test empty stream', () async {
      final stream =
          await createParserFromString('<</Length 0>>stream\nendstream')
              .parse();
      expect(stream, isA<PDFStreamObject>());

      stream as PDFStreamObject;
      expect(stream.dictionary.entries, {
        const PDFName('Length'): const PDFNumber(0),
      });
      expect(stream.length, 0);
      expect(stream.offset, 20);
    });
    test('Test empty stream length indirect', () async {
      final mockParser = _MockIndirectObjectParser();
      when(() => mockParser.getObjectFor(
              const PDFObjectReference(objectId: 1, generationNumber: 0)))
          .thenAnswer((invocation) async => const PDFIndirectObject(
              objectId: 1, generationNumber: 0, object: PDFNumber(0)));
      final stream = await createParserFromString(
        '<</Length 1 0 R>>stream\nendstream',
        mockParser,
      ).parse();
      expect(stream, isA<PDFStreamObject>());

      stream as PDFStreamObject;
      expect(stream.dictionary.entries, {
        const PDFName('Length'):
            const PDFObjectReference(objectId: 1, generationNumber: 0),
      });
      expect(stream.length, 0);
      expect(stream.offset, 24);
    });
    test('Test stream with data', () async {
      final stream =
          await createParserFromString('<</Length 3>>stream\nabcendstream')
              .parse();
      expect(stream, isA<PDFStreamObject>());

      stream as PDFStreamObject;
      expect(stream.dictionary.entries, {
        const PDFName('Length'): const PDFNumber(3),
      });
      expect(stream.length, 3);
      expect(stream.offset, 20);
      final raw = await stream.readRaw();
      expect(raw, [97, 98, 99]);
    });
    test('Test stream extra space, with data', () async {
      final stream =
          await createParserFromString('<</Length 3>>stream \nabcendstream')
              .parse();
      expect(stream, isA<PDFStreamObject>());

      stream as PDFStreamObject;
      expect(stream.dictionary.entries, {
        const PDFName('Length'): const PDFNumber(3),
      });
      expect(stream.length, 3);
      expect(stream.offset, 21);
      final raw = await stream.readRaw();
      expect(raw, [97, 98, 99]);
    });
    test('Test startxref keyword having trailing whitespace', () async {
      final stream =
          await createParserFromString('<</Length 3>>startxref \nabcendstream')
              .parse();
      expect(stream, isA<PDFDictionary>());

      stream as PDFDictionary;
      expect(stream.entries, {
        const PDFName('Length'): const PDFNumber(3),
      });
    });
  });
}
