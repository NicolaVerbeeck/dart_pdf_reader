part of 'pdf_object_parser_test.dart';

void stringParserTests() {
  group('Strings', () {
    group('Literal strings', () {
      test('Test parse normal string', () async {
        final parsed = await createParserFromString('(input)').parse();
        expect(parsed, isA<PDFLiteralString>());
        parsed as PDFLiteralString;
        expect(parsed.asString(), 'input');
      });
      test('Test parse normal string, nested braces', () async {
        final parsed = await createParserFromString('(inp(u)t)').parse();
        expect(parsed, isA<PDFLiteralString>());
        parsed as PDFLiteralString;
        expect(parsed.asString(), 'inp(u)t');
      });
      test('Test parse normal string, escaped brace', () async {
        final parsed = await createParserFromString('(inp\\(ut)').parse();
        expect(parsed, isA<PDFLiteralString>());
        parsed as PDFLiteralString;
        expect(parsed.asString(), 'inp(ut');
      });
      test('Test parse normal string, bad brace', () async {
        expect(createParserFromString('(inp(ut)').parse(),
            throwsA(isA<ParseException>()));
      });
      test('Test escaping', () async {
        final parsed =
            await createParserFromString('(\\n\\r\\t\\(\\)\\\\\\045)').parse();
        expect(parsed, isA<PDFLiteralString>());
        parsed as PDFLiteralString;
        expect(parsed.asString(), '\n\r\t()\\%');
      });
      test('Test new line in string', () async {
        final parsed =
            await createParserFromString('(input\\\r\nhere)').parse();
        expect(parsed, isA<PDFLiteralString>());
        parsed as PDFLiteralString;
        expect(parsed.asString(), 'inputhere');
      });
    });
    group('Hex strings', () {
      test('Test parse hex string', () async {
        final parsed = await createParserFromString('<48656c6c6f>').parse();
        expect(parsed, isA<PDFHexString>());
        parsed as PDFHexString;
        expect(parsed.asString(), 'Hello');
      });
      test('Test parse hex string with comments', () async {
        final parsed =
            await createParserFromString('<48%Very\n656c6c6f>').parse();
        expect(parsed, isA<PDFHexString>());
        parsed as PDFHexString;
        expect(parsed.asString(), 'Hello');
      });
      test('Test parse hex string without ending delimiter', () async {
        expect(createParserFromString('<48656c6c6f').parse(),
            throwsA(isA<ParseException>()));
      });
      test('Test after parse closing bracket is consumed', () async {
        final stream =
            ByteStream(Uint8List.fromList(utf8.encode('<48656c6c6f>a')));
        final parser = createParser(stream);
        final parsed = await parser.parse();
        expect(parsed, isA<PDFHexString>());
        parsed as PDFHexString;
        expect(parsed.asString(), 'Hello');
        expect(await stream.peekByte(), 0x61);
      });
    });
  });
}
