import 'dart:convert';

import 'package:dart_pdf_reader/dart_pdf_reader.dart';
import 'package:dart_pdf_reader/src/model/indirect_object_table.dart';
import 'package:dart_pdf_reader/src/parser/indirect_object_parser.dart';
import 'package:dart_pdf_reader/src/parser/pdf_object_parser.dart';
import 'package:dart_pdf_reader/src/parser/xref_reader.dart';
import 'package:test/test.dart';

void main() {
  PDFObjectParser create(RandomAccessStream stream) {
    final indirectObjectParser =
        IndirectObjectParser(stream, IndirectObjectTable(XRefTable([])));
    return PDFObjectParser(stream, indirectObjectParser);
  }

  group('PDF Object Parser', () {
    group('Strings', () {
      group('Literal strings', () {
        test('Test parse normal string', () async {
          final parsed =
              await create(ByteStream(utf8.encode('(input)'))).parse();
          expect(parsed, isA<PDFLiteralString>());
          parsed as PDFLiteralString;
          expect(parsed.asString(), 'input');
        });
        test('Test parse normal string, nested braces', () async {
          final parsed =
              await create(ByteStream(utf8.encode('(inp(u)t)'))).parse();
          expect(parsed, isA<PDFLiteralString>());
          parsed as PDFLiteralString;
          expect(parsed.asString(), 'inp(u)t');
        });
        test('Test parse normal string, escaped brace', () async {
          final parsed =
              await create(ByteStream(utf8.encode('(inp\\(ut)'))).parse();
          expect(parsed, isA<PDFLiteralString>());
          parsed as PDFLiteralString;
          expect(parsed.asString(), 'inp(ut');
        });
        test('Test parse normal string, bad brace', () async {
          expect(create(ByteStream(utf8.encode('(inp(ut)'))).parse(),
              throwsA(isA<ParseException>()));
        });
        test('Test escaping', () async {
          final parsed = await create(
                  ByteStream(utf8.encode('(\\n\\r\\t\\(\\)\\\\\\045)')))
              .parse();
          expect(parsed, isA<PDFLiteralString>());
          parsed as PDFLiteralString;
          expect(parsed.asString(), '\n\r\t()\\%');
        });
        test('Test new line in string', () async {
          final parsed =
              await create(ByteStream(utf8.encode('(input\\\r\nhere)')))
                  .parse();
          expect(parsed, isA<PDFLiteralString>());
          parsed as PDFLiteralString;
          expect(parsed.asString(), 'inputhere');
        });
      });
      group('Hex strings', () {
        test('Test parse hex string', () async {
          final parsed =
              await create(ByteStream(utf8.encode('<48656c6c6f>'))).parse();
          expect(parsed, isA<PDFHexString>());
          parsed as PDFHexString;
          expect(parsed.asString(), 'Hello');
        });
        test('Test parse hex string with comments', () async {
          final parsed =
              await create(ByteStream(utf8.encode('<48%Very\n656c6c6f>')))
                  .parse();
          expect(parsed, isA<PDFHexString>());
          parsed as PDFHexString;
          expect(parsed.asString(), 'Hello');
        });
        test('Test parse hex string without ending delimiter', () async {
          expect(create(ByteStream(utf8.encode('<48656c6c6f'))).parse(),
              throwsA(isA<ParseException>()));
        });
      });
    });
  });
}
