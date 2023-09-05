import 'package:dart_pdf_reader/src/model/pdf_constants.dart';
import 'package:dart_pdf_reader/src/model/pdf_document_catalog.dart';
import 'package:dart_pdf_reader/src/model/pdf_types.dart';
import 'package:dart_pdf_reader/src/parser/object_resolver.dart';

/// Holds the data for the PDF document.
class PDFDocument {
  /// The document main trailer
  final PDFDictionary mainTrailer;
  final ObjectResolver _objectResolver;

  /// Extracts the [PDFDocumentCatalog] from the document
  Future<PDFDocumentCatalog> get catalog async {
    final dict = await resolve<PDFDictionary>(mainTrailer[PDFNames.root]);
    return PDFDocumentCatalog(this, dict!, _objectResolver);
  }

  /// Create a new instance of [PDFDocument]
  PDFDocument({
    required this.mainTrailer,
    required ObjectResolver objectResolver,
  }) : _objectResolver = objectResolver;

  /// Resolves the [PDFObject] to its actual value, reading it from the document
  /// as needed
  Future<T?> resolve<T extends PDFObject>(PDFObject? toResolve) {
    return _objectResolver.resolve(toResolve);
  }
}
