import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_pdf_reader/dart_pdf_reader.dart';
import 'package:dart_pdf_reader/src/model/indirect_object_table.dart';
import 'package:dart_pdf_reader/src/parser/indirect_object_parser.dart';
import 'package:dart_pdf_reader/src/parser/xref_reader.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockIndirectObjectTable extends Mock implements IndirectObjectTable {}

void main() {
  group('IndirectObjectParser tests', () {
    late MockIndirectObjectTable indirectObjectTable;
    late IndirectObjectParser indirectObjectParser;
    late RandomAccessStream buffer;

    setUp(() {
      indirectObjectTable = MockIndirectObjectTable();
      buffer = ByteStream(Uint8List.fromList(utf8
          .encode('2 0 obj\n<</Test/Me>>\nendobj\n1 0 obj\n-98.1827\nendobj')));
      indirectObjectParser = IndirectObjectParser(buffer, indirectObjectTable);
    });

    test('Test reference exists', () async {
      when(() => indirectObjectTable[1]).thenReturn(const PDFIndirectObject(
        object: PDFNumber(-98.1827),
        generationNumber: 0,
        objectId: 1,
      ));
      final obj = await indirectObjectParser
          .getObjectFor(const PDFObjectReference(objectId: 1));
      expect(obj, const PDFNumber(-98.1827));
    });
    test('Test readObject', () async {
      when(() => indirectObjectTable[1]).thenReturn(null);
      when(() => indirectObjectTable.getObjectReferenceFor(1)).thenReturn(
        const XRefEntry(
          id: 1,
          offset: 28,
          generation: 0,
          free: false,
        ),
      );

      final obj = await indirectObjectParser.getObjectFor(
        const PDFObjectReference(objectId: 1),
      );
      obj as PDFIndirectObject;
      expect(obj.object, const PDFNumber(-98.1827));
    });
  });
}
