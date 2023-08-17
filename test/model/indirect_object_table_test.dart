import 'package:dart_pdf_reader/dart_pdf_reader.dart';
import 'package:dart_pdf_reader/src/model/indirect_object_table.dart';
import 'package:dart_pdf_reader/src/parser/xref_reader.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockXRefTable extends Mock implements XRefTable {}

class _XRefSubsection extends Mock implements XRefSubsection {}

void main() {
  group('IndirectObjectTable tests', () {
    test('Test add object', () {
      final xrefTable = _MockXRefTable();
      final sut = IndirectObjectTable(xrefTable);
      final obj = const PDFIndirectObject(
          objectId: 0, generationNumber: 0, object: PDFNumber(1337));
      expect(sut[0], isNull);
      sut.put(0, obj);
      expect(sut[0], obj);
    });

    test('Test resolve object reference', () {
      final xrefTable = _MockXRefTable();
      final sut = IndirectObjectTable(xrefTable);
      final obj = const PDFObjectReference(objectId: 1, generationNumber: 0);
      expect(sut.resolve<PDFNumber>(obj), null);

      final newObj = const PDFIndirectObject(
          objectId: 1, generationNumber: 0, object: PDFNumber(1337));
      sut.put(1, newObj);
      expect(sut.resolve<PDFNumber>(obj), newObj.object);
    });

    test('Test resolve direct object', () {
      final xrefTable = _MockXRefTable();
      final sut = IndirectObjectTable(xrefTable);
      final obj = const PDFNumber(1337);
      expect(sut.resolve<PDFNumber>(obj), obj);
    });

    test('Test find entry in xref', () {
      final section = _XRefSubsection();
      final xrefTable = _MockXRefTable();
      when(() => xrefTable.sections).thenReturn([section]);
      when(() => section.hasId(1)).thenReturn(true);
      when(() => section.hasId(2)).thenReturn(false);

      const entry = XRefEntry(id: 1, offset: 2, generation: 3, free: false);
      when(() => section.getObject(1)).thenReturn(entry);

      final sut = IndirectObjectTable(xrefTable);
      expect(sut.getObjectReferenceFor(2), isNull);
      expect(sut.getObjectReferenceFor(1), entry);
    });
  });
}
