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
    final dict = await _objectResolver
        .resolve<PDFDictionary>(mainTrailer[const PDFName('Root')]);
    return PDFDocumentCatalog(this, dict!, _objectResolver);
  }

  /// Create a new instance of [PDFDocument]
  PDFDocument({
    required this.mainTrailer,
    required ObjectResolver objectResolver,
  }) : _objectResolver = objectResolver;
}

extension DocExt on PDFDocument {
  ObjectResolver get objectResolver => _objectResolver;
}
