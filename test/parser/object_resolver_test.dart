import 'package:dart_pdf_reader/src/model/indirect_object_table.dart';
import 'package:dart_pdf_reader/src/model/pdf_types.dart';
import 'package:dart_pdf_reader/src/parser/indirect_object_parser.dart';
import 'package:dart_pdf_reader/src/parser/object_resolver.dart';
import 'package:dart_pdf_reader/src/parser/xref_reader.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockIndirectObjectParser extends Mock implements IndirectObjectParser {}

class MockIndirectObjectTable extends Mock implements IndirectObjectTable {}

void main() {
  group('ObjectResolver tests', () {
    late MockIndirectObjectParser indirectObjectParser;
    late MockIndirectObjectTable indirectObjectTable;
    late ObjectResolver objectResolver;

    setUp(() {
      indirectObjectParser = MockIndirectObjectParser();
      indirectObjectTable = MockIndirectObjectTable();
      objectResolver =
          ObjectResolver(indirectObjectParser, indirectObjectTable);
    });

    test('Test resolve null', () async {
      expect(await objectResolver.resolve(null), isNull);
    });
    test('Test resolve regular object', () async {
      final object = const PDFNumber(-98.1827);
      expect(await objectResolver.resolve(object), const PDFNumber(-98.1827));
    });
    test('Test resolve indirect object', () async {
      final indirectObject = const PDFIndirectObject(
        object: PDFNumber(-98.1827),
        generationNumber: 0,
        objectId: 1,
      );
      expect(await objectResolver.resolve(indirectObject),
          const PDFNumber(-98.1827));
    });
    test('Test resolve indirect object twice', () async {
      final indirectObject = const PDFIndirectObject(
        object: PDFIndirectObject(
          object: PDFNumber(-98.1827),
          generationNumber: 0,
          objectId: 2,
        ),
        generationNumber: 0,
        objectId: 1,
      );
      expect(await objectResolver.resolve(indirectObject),
          const PDFNumber(-98.1827));
    });
    test('Test resolve known reference', () async {
      when(() => indirectObjectTable[1]).thenReturn(const PDFIndirectObject(
        object: PDFNumber(-98.1827),
        generationNumber: 0,
        objectId: 1,
      ));
      expect(
          await objectResolver.resolve(const PDFObjectReference(
            objectId: 1,
            generationNumber: 0,
          )),
          const PDFNumber(-98.1827));
    });
    test('Test resolve read reference', () async {
      when(() => indirectObjectTable[1]).thenReturn(null);
      when(() => indirectObjectTable.getObjectReferenceFor(1))
          .thenReturn(const XRefEntry(
        id: 1,
        offset: 2,
        generation: 0,
        free: false,
      ));
      when(() => indirectObjectParser.readObjectAt(const XRefEntry(
            id: 1,
            offset: 2,
            generation: 0,
            free: false,
          ))).thenAnswer((_) async => const PDFIndirectObject(
            object: PDFNumber(-98.1827),
            generationNumber: 0,
            objectId: 1,
          ));
      expect(
          await objectResolver.resolve(const PDFObjectReference(
            objectId: 1,
            generationNumber: 0,
          )),
          const PDFNumber(-98.1827));
    });
  });
}
