import 'package:dart_pdf_reader/src/model/indirect_object_table.dart';
import 'package:dart_pdf_reader/src/model/pdf_types.dart';
import 'package:dart_pdf_reader/src/parser/indirect_object_parser.dart';

class ObjectResolver {
  final IndirectObjectParser _indirectObjectParser;
  final IndirectObjectTable _indirectObjectTable;

  ObjectResolver(
    this._indirectObjectParser,
    this._indirectObjectTable,
  );

  Future<T?> resolve<T extends PDFObject>(PDFObject? toResolve) async {
    if (toResolve is PDFIndirectObject) {
      return resolve(toResolve.object);
    } else if (toResolve is PDFObjectReference) {
      return resolve(await getObject(toResolve.objectId));
    }
    return toResolve as T?;
  }

  Future<PDFObject?> getObject(int id) {
    final indirectObject = _indirectObjectTable[id];
    if (indirectObject != null) {
      return Future.value(indirectObject.object);
    }
    return _indirectObjectParser
        .readObjectAt(_indirectObjectTable.getObjectReferenceFor(id)!)
        .then((value) => value.object);
  }
}
