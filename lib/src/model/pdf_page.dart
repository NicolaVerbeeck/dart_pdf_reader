import 'dart:math';

import '../error/exceptions.dart';
import 'pdf_constants.dart';
import 'pdf_document.dart';
import 'pdf_types.dart';
import '../parser/object_resolver.dart';

/// Pages tree root of the document
class PDFPages {
  final PDFPageTreeNode _root;

  /// The number of pages in the document
  int get pageCount => _root.length;

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
    final count = node.length;
    if (pageNum <= encountered + count) {
      for (final kid in node._children) {
        if (kid is PDFPageTreeNode) {
          final kidCount = kid.length;
          if (pageNum <= encountered + kidCount) {
            return _get(pageNum, kid, encountered);
          } else {
            encountered += kidCount;
          }
        } else {
          ++encountered;
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

  // coverage:ignore-start
  @override
  String toString() {
    return 'PDFPages{root: $_root}';
  }
// coverage:ignore-end
}

abstract class PDFPageNode {
  /// The document this page belongs to
  final PDFDocument document;

  /// The parent of this page
  final PDFPageNode? parent;
  final ObjectResolver objectResolver;
  final PDFDictionary _dictionary;

  /// The dictionary of this page
  PDFDictionary get dictionary => _dictionary;

  /// Deprecated, use [contentStreams] instead.
  ///
  /// Reads this page's content stream if present. If multiple content streams
  /// are present, only the first one is returned.
  @Deprecated(
      'Always returns the first content stream. Use contentStreams instead')
  Future<PDFStreamObject?> get contentStream =>
      contentStreams.then((value) => value?.first);

  /// Reads this page's content streams if present
  /// If this page contains a single content stream, it is returned as a list
  /// with a single element.
  Future<List<PDFStreamObject>?> get contentStreams async {
    final resolved =
        await objectResolver.resolve(_dictionary[PDFNames.contents]);
    if (resolved == null) {
      return null;
    } else if (resolved is PDFStreamObject) {
      return [resolved];
    } else if (resolved is PDFArray) {
      final list = <PDFStreamObject>[];
      for (final e in resolved) {
        final stream = (await objectResolver.resolve<PDFStreamObject>(e))!;
        list.add(stream);
      }
      return list;
    } else {
      throw const ParseException(
          'Invalid PDF, contents neither stream nor array');
    }
  }

  /// Reads this page's resources if present
  Future<PDFDictionary?> get resources =>
      objectResolver.resolve(_dictionary[PDFNames.resources]);

  /// Creates a new pdf page node
  PDFPageNode(
    this.document,
    this.parent,
    this.objectResolver,
    this._dictionary,
  );

  // coverage:ignore-start
  @override
  String toString() {
    return 'PDFPageNode{_dictionary: $_dictionary}';
  }

  // coverage:ignore-end

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

  // coverage:ignore-start
  @override
  String toString() {
    return 'PDFPageTreeNode{children: ${_children.length}::${super.toString()}';
  }
// coverage:ignore-end
}

/// A single page of the document
class PDFPageObjectNode extends PDFPageNode {
  late final PDFArray? _mediaBox = getOrInherited(PDFNames.mediaBox);
  late final PDFArray? _cropBox = getOrInherited(PDFNames.cropBox);
  late final PDFArray? _artBox = getOrInherited(PDFNames.artBox);
  late final PDFArray? _bleedBox = getOrInherited(PDFNames.bleedBox);
  late final PDFArray? _trimBox = getOrInherited(PDFNames.trimBox);

  /// Reads and parses this page's media box into a rectangle
  late final Rectangle<double> mediaBox = _toRect(_mediaBox!)!;

  /// Reads and parses this page's crop box into a rectangle
  late final Rectangle<double>? cropBox = _toRect(_cropBox);

  /// Reads and parses this page's art box into a rectangle
  late final Rectangle<double>? artBox = _toRect(_artBox);

  /// Reads and parses this page's bleed box into a rectangle
  late final Rectangle<double>? bleedBox = _toRect(_bleedBox);

  /// Reads and parses this page's trim box into a rectangle
  late final Rectangle<double>? trimBox = _toRect(_trimBox);

  late final PDFNumber? rotate = getOrInherited(PDFNames.rotate);

  /// Creates a new pdf page object node
  PDFPageObjectNode(
    super.document,
    super.parent,
    super.objectResolver,
    super.dictionary,
  );

  // coverage:ignore-start
  @override
  String toString() {
    return 'PDFPageObjectNode{}::${super.toString()}';
  }
  // coverage:ignore-end

  Rectangle<double>? _toRect(PDFArray? array) {
    if (array == null) return null;
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
