import 'dart:math';

import 'package:dart_pdf_reader/src/model/pdf_document.dart';
import 'package:dart_pdf_reader/src/model/pdf_types.dart';
import 'package:dart_pdf_reader/src/parser/object_resolver.dart';

class PDFPages {
  final PDFPageTreeNode _root;

  PDFPages(this._root);

  PDFPageObjectNode getPageAtIndex(int index) => _get(index + 1, _root, 0);

  PDFPageObjectNode _get(int pageNum, PDFPageNode node, int encountered) {
    if (node is! PDFPageTreeNode) {
      if (encountered == pageNum) {
        return node as PDFPageObjectNode;
      } else {
        throw Exception('Page not found');
      }
    }
    final count = node.length;
    if (pageNum <= encountered + count) {
      for (final PDFPageNode kid in node._children) {
        if (kid is PDFPageTreeNode) {
          final kidCount = kid.length;
          if (pageNum <= encountered + kidCount) {
            return _get(pageNum, kid, encountered);
          } else {
            encountered += kidCount;
          }
        } else {
          encountered++;
          if (encountered == pageNum) {
            return kid as PDFPageObjectNode;
          }
        }
      }
      throw Exception('Page not found');
    } else {
      throw Exception(
          'Index out of bounds: $pageNum (max: ${encountered + count})');
    }
  }

  @override
  String toString() {
    return 'PDFPages{root: $_root}';
  }
}

class PDFPageNode {
  final PDFDocument document;
  final PDFPageNode? parent;
  final ObjectResolver _objectResolver;
  final PDFDictionary _dictionary;

  PDFDictionary get dictionary => _dictionary;

  Future<PDFStreamObject?> get contentStream =>
      _objectResolver.resolve(_dictionary[const PDFName('Contents')]);

  Future<PDFDictionary?> get resources =>
      _objectResolver.resolve(_dictionary[const PDFName('Resources')]);

  PDFPageNode(
    this.document,
    this.parent,
    this._objectResolver,
    this._dictionary,
  );

  @override
  String toString() {
    return 'PDFPageNode{_dictionary: $_dictionary}';
  }

  T? getOrInherited<T extends PDFObject>(PDFName name) {
    final self = _dictionary[name];
    if (self != null) return self as T;
    if (parent != null) {
      return parent!.getOrInherited(name);
    }
    return null;
  }
}

class PDFPageTreeNode extends PDFPageNode {
  final List<PDFPageNode> _children;
  final int length;

  PDFPageTreeNode(
    super.document,
    super.parent,
    super.objectResolver,
    super.dictionary,
    this._children,
    this.length,
  );

  PDFPageNode operator [](int index) => _children[index];

  @override
  String toString() {
    return 'PDFPageTreeNode{children: ${_children.length}::${super.toString()}';
  }
}

class PDFPageObjectNode extends PDFPageNode {
  static const xObjectsExcludedKeys = [
    PDFName('MediaBox'),
    PDFName('CropBox'),
    PDFName('TrimBox'),
    PDFName('Contents'),
    PDFName('Parent'),
    PDFName('Annots'),
    PDFName('StructParents'),
    PDFName('B'),
    PDFName('Type'),
  ];

  late final PDFArray? _mediaBox = getOrInherited(const PDFName('MediaBox'));

  late final Rectangle<double> mediaBox = _toRect(_mediaBox!);

  PDFPageObjectNode(
    super.document,
    super.parent,
    super.objectResolver,
    super.dictionary,
  );

  @override
  String toString() {
    return 'PDFPageObjectNode{}::${super.toString()}';
  }

  Rectangle<double> _toRect(PDFArray array) {
    if (array.length < 4) {
      throw ArgumentError(
          'Invalid rectangle, expected 4 elements, got ${array.length}');
    }
    final llx = (array[0] as PDFNumber).toDouble();
    final lly = (array[1] as PDFNumber).toDouble();
    final urx = (array[2] as PDFNumber).toDouble();
    final ury = (array[3] as PDFNumber).toDouble();

    return Rectangle(
      min(llx, urx),
      min(lly, ury),
      (urx - llx).abs(),
      (ury - lly).abs(),
    );
  }
}
