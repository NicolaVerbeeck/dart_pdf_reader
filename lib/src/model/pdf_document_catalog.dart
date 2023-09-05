import 'package:dart_pdf_reader/src/model/pdf_constants.dart';
import 'package:dart_pdf_reader/src/model/pdf_document.dart';
import 'package:dart_pdf_reader/src/model/pdf_outline.dart';
import 'package:dart_pdf_reader/src/model/pdf_page.dart';
import 'package:dart_pdf_reader/src/model/pdf_types.dart';
import 'package:dart_pdf_reader/src/parser/object_resolver.dart';

/// The document catalog describing the document
class PDFDocumentCatalog {
  final PDFDictionary dictionary;
  final ObjectResolver resolver;
  final PDFDocument document;

  /// Create a new instance of [PDFDocumentCatalog]
  PDFDocumentCatalog(
    this.document,
    this.dictionary,
    this.resolver,
  );

  /// Reads the document's pages into a [PDFPages] object
  Future<PDFPages> getPages() async {
    final pagesRoot =
        (await resolver.resolve<PDFDictionary>(dictionary[PDFNames.pages]))!;
    final pageRoot = await _readPageTree(pagesRoot, parent: null);
    return PDFPages(pageRoot);
  }

  /// Reads the document's outlines into a [List] of [PDFOutlineItem]s
  /// Currently only action outlines are supported, destination outlines are not
  /// supported yet. Outlines that are not supported will be ignored.
  /// You can register custom logic for creating [PDFOutlineItem]s by using
  /// [PDFOutlineAction.registerOutlineCreator].
  Future<List<PDFOutlineItem>?> getOutlines() async {
    final dict =
        await resolver.resolve<PDFDictionary>(dictionary[PDFNames.outlines]);

    if (dict == null) {
      return null;
    }

    return _readOutlines(dict);
  }

  /// Reads the document's version into a version string
  Future<String?> getVersion() {
    return resolver
        .resolve<PDFStringLike>(dictionary[PDFNames.version])
        .then((value) => value?.asString());
  }

  /// Reads the document's language into a language string
  Future<String?> getLanguage() {
    return resolver
        .resolve<PDFStringLike>(dictionary[PDFNames.lang])
        .then((value) => value?.asString());
  }

  Future<PDFPageTreeNode> _readPageTree(
    PDFDictionary pagesRoot, {
    required PDFPageNode? parent,
  }) async {
    final kidsArray =
        (await resolver.resolve<PDFArray>(pagesRoot[PDFNames.kids]))!;

    final children = <PDFPageNode>[];
    final treeNode = PDFPageTreeNode(
      document,
      parent,
      resolver,
      pagesRoot,
      children,
      (await resolver.resolve<PDFNumber>(pagesRoot[PDFNames.count]))!.toInt(),
    );

    for (final kid in kidsArray) {
      final childObject = (await resolver.resolve<PDFDictionary>(kid))!;
      final type = (childObject[PDFNames.type] as PDFName).value;
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
        PDFPageObjectNode(document, parent, resolver, childObject));
  }

  Future<List<PDFOutlineItem>> _readOutlines(PDFDictionary dictionary) async {
    final firstRef =
        await resolver.resolve<PDFDictionary>(dictionary[PDFNames.first]);

    PDFDictionary? currentOutline = firstRef;

    final outlines = <PDFOutlineItem>[];

    while (currentOutline != null) {
      final title = currentOutline[PDFNames.title] as PDFLiteralString;
      final nextRef =
          await resolver.resolve<PDFDictionary>(currentOutline[PDFNames.next]);

      final destRef = currentOutline[PDFNames.dest];
      if (destRef != null) {
        // TODO: Destination outline is not supported yet
        continue;
      }
      final action =
          await resolver.resolve<PDFDictionary>(currentOutline[PDFNames.a]);

      if (action != null) {
        try {
          outlines.add(
            PDFOutlineItem(
              title: title.asString(),
              action: PDFOutlineAction.fromDictionary(action),
            ),
          );
        } catch (e) {
          // TODO: This outline action is not supported yet
          continue;
        }
      }

      /// set the next outline
      currentOutline = nextRef;
    }

    return outlines;
  }
}
