import 'package:dart_pdf_reader/dart_pdf_reader.dart';

class PDFBookmark {
  const PDFBookmark({
    required this.title,
    required this.pageNumber,
    this.ref,
  });

  final String title;
  final int pageNumber;
  final PDFObjectReference? ref;

  @override
  String toString() {
    return 'PDFBookmark{title: $title, pageNumber: $pageNumber, ref: $ref}';
  }
}
