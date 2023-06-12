import 'package:dart_pdf_reader/src/model/pdf_document.dart';
import 'package:dart_pdf_reader/src/model/pdf_page.dart';
import 'package:dart_pdf_reader/src/model/pdf_types.dart';
import 'package:dart_pdf_reader/src/parser/object_resolver.dart';

/// The document catalog describing the document
class PDFDocumentCatalog {
  final PDFDictionary _dictionary;
  final ObjectResolver _resolver;
  final PDFDocument _document;

  /// Create a new instance of [PDFDocumentCatalog]
  PDFDocumentCatalog(
    this._document,
    this._dictionary,
    this._resolver,
  );

  /// Reads the document's pages into a [PDFPages] object
  Future<PDFPages> getPages() async {
    final pagesRoot =
        (await _resolver.resolve(_dictionary[const PDFName('Pages')]))!;
    final pageRoot = await _readPageTree(pagesRoot, parent: null);
    return PDFPages(pageRoot);
  }

  /// Reads the document's version into a version string
  Future<String?> getVersion() async {
    return _resolver
        .resolve<PDFStringLike>(_dictionary[const PDFName('Version')])
        .then((value) => value?.asString());
  }

  /// Reads the document's language into a language string
  Future<String?> getLanguage() async {
    return _resolver
        .resolve<PDFStringLike>(_dictionary[const PDFName('Lang')])
        .then((value) => value?.asString());
  }

  Future<PDFPageTreeNode> _readPageTree(
    PDFObject pagesRoot, {
    required PDFPageNode? parent,
  }) async {
    pagesRoot as PDFDictionary;
    final kidsArray =
        await _resolver.resolve(pagesRoot[const PDFName('Kids')]) as PDFArray;

    final children = <PDFPageNode>[];
    final treeNode = PDFPageTreeNode(
      _document,
      parent,
      _resolver,
      pagesRoot,
      children,
      (await _resolver.resolve(pagesRoot[const PDFName('Count')]) as PDFNumber)
          .toInt(),
    );

    for (final kid in kidsArray) {
      final childObject = await _resolver.resolve(kid) as PDFDictionary;
      final type = (childObject[const PDFName('Type')] as PDFName).value;
      switch (type) {
        case 'Pages':
          children.add(await _readPageTree(childObject, parent: treeNode));
          break;
        case 'Page':
          children.add(await _readPage(childObject, parent: treeNode));
          break;
        default:
          throw Exception('Unknown page type: $type');
      }
    }
    return treeNode;
  }

  Future<PDFPageNode> _readPage(PDFDictionary childObject,
      {required PDFPageTreeNode parent}) {
    return Future.value(
        PDFPageObjectNode(_document, parent, _resolver, childObject));
  }
}
