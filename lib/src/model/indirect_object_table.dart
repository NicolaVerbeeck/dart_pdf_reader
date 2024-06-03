import 'pdf_types.dart';
import '../parser/xref_reader.dart';

class IndirectObjectTable {
  final XRefTable _xrefTable;
  final _loadedObjects = <int, PDFIndirectObject>{};

  IndirectObjectTable(this._xrefTable);

  PDFIndirectObject? operator [](int objectId) => _loadedObjects[objectId];

  XRefEntry? getObjectReferenceFor(int objectId) {
    for (final section in _xrefTable.sections) {
      if (section.hasId(objectId)) return section.getObject(objectId);
    }
    return null;
  }

  void put(int objectId, PDFIndirectObject object) {
    if (!_loadedObjects.containsKey(objectId)) {
      _loadedObjects[objectId] = object;
    }
  }

  T? resolve<T>(PDFObject? toResolve) {
    if (toResolve is PDFIndirectObject) {
      return resolve(toResolve.object);
    } else if (toResolve is PDFObjectReference) {
      return resolve(this[toResolve.objectId]);
    }
    return toResolve as T?;
  }
}
