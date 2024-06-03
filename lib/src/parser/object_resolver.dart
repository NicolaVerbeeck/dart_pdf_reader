import '../model/indirect_object_table.dart';
import '../model/pdf_types.dart';
import 'indirect_object_parser.dart';

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
