import 'package:dart_pdf_reader/src/model/indirect_object_table.dart';
import 'package:dart_pdf_reader/src/model/pdf_document_catalog.dart';
import 'package:dart_pdf_reader/src/model/pdf_types.dart';
import 'package:dart_pdf_reader/src/parser/object_resolver.dart';
import 'package:dart_pdf_reader/src/parser/xref_reader.dart';

class PDFDocument {
  final XRefTable xrefTable;
  final PDFDictionary mainTrailer;
  final IndirectObjectTable _indirectObjectTable;
  final ObjectResolver objectResolver;

  Future<PDFDocumentCatalog> get catalog async {
    final dict = await objectResolver
        .resolve<PDFDictionary>(mainTrailer[const PDFName('Root')]);
    return PDFDocumentCatalog(this, dict!, objectResolver);
  }

  PDFDocument({
    required this.xrefTable,
    required this.mainTrailer,
    required IndirectObjectTable indirectObjectTable,
    required this.objectResolver,
  }) : _indirectObjectTable = indirectObjectTable;
}
