import '../model/indirect_object_table.dart';
import '../model/pdf_types.dart';
import 'indirect_object_parser.dart';

/// Helper to resolve indirect objects to their actual object.
class ObjectResolver {
  final IndirectObjectParser _indirectObjectParser;
  final IndirectObjectTable _indirectObjectTable;
  final bool _cacheResolvedObjects;

  ObjectResolver(
    this._indirectObjectParser,
    this._indirectObjectTable, {
    /// Hint indicating if resolved objects should be cached.
    /// This is useful when the same object is resolved multiple times.
    /// Default is `true`.
    /// Note: This is only a hint
    bool cacheResolvedObjects = true,
  }) : _cacheResolvedObjects = cacheResolvedObjects;

  /// Resolves the given object to its actual object, reading it from the document
  /// if necessary.
  Future<T?> resolve<T extends PDFObject>(PDFObject? toResolve) async {
    if (toResolve is PDFIndirectObject) {
      return resolve(toResolve.object);
    } else if (toResolve is PDFObjectReference) {
      return resolve(await getObject(toResolve.objectId));
    }
    return toResolve as T?;
  }

  /// Gets the object with the given id.
  Future<PDFObject?> getObject(int id) {
    final indirectObject = _indirectObjectTable[id];
    if (indirectObject != null) {
      return Future.value(indirectObject.object);
    }
    return _indirectObjectParser
        .readObjectAt(
          _indirectObjectTable.getObjectReferenceFor(id)!,
          memoryCache: _cacheResolvedObjects,
        )
        .then((value) => value.object);
  }
}
