import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:dart_pdf_reader/dart_pdf_reader.dart';
import 'package:dart_pdf_reader/src/model/indirect_object_table.dart';
import 'package:dart_pdf_reader/src/parser/indirect_object_parser.dart';
import 'package:dart_pdf_reader/src/parser/pdf_parser.dart';
import 'package:dart_pdf_reader/src/parser/xref_reader.dart';
import 'package:test/test.dart';

void main() {
  group('PDFParser tests', () {
    group('Parse document', () {
      test('it supports single main xref', () async {
        final stream = ByteStream(Uint8List.fromList(utf8.encode(
            'xref\n0 1\n0000000000 65535 f\r\ntrailer\n<< /Size 1 /Root 1 0 R >>\nstartxref\n0\n%%EOF')));

        final parser = PDFParser(stream);

        final document = await parser.parse();

        expect(
            document.mainTrailer,
            PDFDictionary({
              const PDFName('Size'): const PDFNumber(1),
              const PDFName('Root'):
                  const PDFObjectReference(objectId: 1, generationNumber: 0),
            }));
      });
    });

    group('parseTrailer', () {
      test('parses trailer', () async {
        final stream = ByteStream(Uint8List.fromList(utf8.encode(
            'trailer\n<< /Size 74 /ID [<31415926535897932384626433832795><31415926535897932384626433832795>] >>')));

        final indirectObjectParser = IndirectObjectParser(
            stream, IndirectObjectTable(const XRefTable([])));

        expect(
            await parseTrailer(indirectObjectParser, stream),
            PDFDictionary({
              const PDFName('Size'): const PDFNumber(74),
              const PDFName('ID'): PDFArray([
                PDFHexString(Uint8List.fromList(
                    hex.decode('31415926535897932384626433832795'))),
                PDFHexString(Uint8List.fromList(
                    hex.decode('31415926535897932384626433832795'))),
              ]),
            }));
      });
      test('parser trailer without newline', () async {
        final stream = ByteStream(Uint8List.fromList(utf8.encode(
            'trailer << /Size 74 /ID [<31415926535897932384626433832795><31415926535897932384626433832795>] >>')));

        final indirectObjectParser = IndirectObjectParser(
            stream, IndirectObjectTable(const XRefTable([])));

        expect(
            await parseTrailer(indirectObjectParser, stream),
            PDFDictionary({
              const PDFName('Size'): const PDFNumber(74),
              const PDFName('ID'): PDFArray([
                PDFHexString(Uint8List.fromList(
                    hex.decode('31415926535897932384626433832795'))),
                PDFHexString(Uint8List.fromList(
                    hex.decode('31415926535897932384626433832795'))),
              ]),
            }));
      });
    });
  });
}
