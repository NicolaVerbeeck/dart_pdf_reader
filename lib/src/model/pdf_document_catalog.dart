import 'package:dart_pdf_reader/src/model/pdf_document.dart';
import 'package:dart_pdf_reader/src/model/pdf_outline.dart';
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

  /// Reads the document's outlines into a [List] of [PDFOutlineItem]s
  /// Currently only action outlines are supported, destination outlines are not
  /// supported yet. Outlines that are not supported will be ignored.
  /// You can register custom logic for creating [PDFOutlineItem]s by using
  /// [PDFOutlineAction.registerOutlineCreator].
  Future<List<PDFOutlineItem>?> getOutlines() async {
    final dict = await _resolver
        .resolve<PDFDictionary>(_dictionary[const PDFName('Outlines')]);

    if (dict == null) {
      return null;
    }

    return _readOutlines(dict);
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

  Future<List<PDFOutlineItem>> _readOutlines(PDFDictionary dictionary) async {
    final firstRef = dictionary[const PDFName('First')] as PDFObjectReference;

    PDFObjectReference? currentOutlineRef = firstRef;

    final outlines = <PDFOutlineItem>[];

    while (currentOutlineRef != null) {
      final currentOutline = await _resolver.resolve(currentOutlineRef);

      /// If we can't resolve the current outline, cancel
      if (currentOutline == null) {
        break;
      }

      final title = (currentOutline as PDFDictionary)[const PDFName('Title')]
          as PDFLiteralString;
      final nextRef =
          currentOutline[const PDFName('Next')] as PDFObjectReference?;

      /// set the next outline
      currentOutlineRef = nextRef;
      final actionRef =
          currentOutline[const PDFName('A')] as PDFObjectReference?;
      final destRef =
          currentOutline[const PDFName('Dest')] as PDFObjectReference?;

      if (destRef != null) {
        // TODO: Destination outline is not supported yet
        continue;
      } else if (actionRef != null) {
        final action = await _resolver.resolve(actionRef) as PDFDictionary;
        try {
          outlines.add(PDFOutlineItem(
            title: title.asString(),
            action: PDFOutlineAction.fromDictionary(action),
          ));
        } catch (e) {
          // TODO: This outline action is not supported yet
          continue;
        }
      }
    }

    return outlines;
  }
}
