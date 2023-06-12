import 'dart:math';

import 'package:dart_pdf_reader/src/model/pdf_document.dart';
import 'package:dart_pdf_reader/src/model/pdf_types.dart';
import 'package:dart_pdf_reader/src/parser/object_resolver.dart';

/// Pages tree root of the document
class PDFPages {
  final PDFPageTreeNode _root;

  /// Create a new instance of [PDFPages]
  PDFPages(this._root);

  /// Gets the page at the given index. Indexes start at 0. If the page
  /// with the given index could not be found, an exception is thrown.
  PDFPageObjectNode getPageAtIndex(int index) => _get(index + 1, _root, 0);

  PDFPageObjectNode _get(int pageNum, PDFPageNode node, int encountered) {
    if (node is! PDFPageTreeNode) {
      if (encountered == pageNum) {
        return node as PDFPageObjectNode;
      } else {
        throw Exception('Page not found');
      }
    }
    final count = node._length;
    if (pageNum <= encountered + count) {
      for (final PDFPageNode kid in node._children) {
        if (kid is PDFPageTreeNode) {
          final kidCount = kid._length;
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

abstract class PDFPageNode {
  /// The document this page belongs to
  final PDFDocument document;

  /// The parent of this page
  final PDFPageNode? parent;
  final ObjectResolver _objectResolver;
  final PDFDictionary _dictionary;

  /// The dictionary of this page
  PDFDictionary get dictionary => _dictionary;

  /// Reads this page's content stream if present
  Future<PDFStreamObject?> get contentStream =>
      _objectResolver.resolve(_dictionary[const PDFName('Contents')]);

  /// Reads this page's resources if present
  Future<PDFDictionary?> get resources =>
      _objectResolver.resolve(_dictionary[const PDFName('Resources')]);

  /// Creates a new pdf page node
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

  /// Gets the value of the given key from this page's dictionary. If the key
  /// is not present, the parent's dictionary is searched and so on and so on
  T? getOrInherited<T extends PDFObject>(PDFName name) {
    final self = _dictionary[name];
    if (self != null) return self as T;
    if (parent != null) {
      return parent!.getOrInherited(name);
    }
    return null;
  }
}

/// An intermediate node in the pages tree
class PDFPageTreeNode extends PDFPageNode {
  final List<PDFPageNode> _children;
  final int _length;

  PDFPageTreeNode(
    super.document,
    super.parent,
    super.objectResolver,
    super.dictionary,
    this._children,
    this._length,
  );

  PDFPageNode operator [](int index) => _children[index];

  @override
  String toString() {
    return 'PDFPageTreeNode{children: ${_children.length}::${super.toString()}';
  }
}

/// A single page of the document
class PDFPageObjectNode extends PDFPageNode {
  late final PDFArray? _mediaBox = getOrInherited(const PDFName('MediaBox'));

  /// Reads and parses this page's media box into a rectangle
  late final Rectangle<double> mediaBox = _toRect(_mediaBox!);

  /// Creates a new pdf page object node
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
