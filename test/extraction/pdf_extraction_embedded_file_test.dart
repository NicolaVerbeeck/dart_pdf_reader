import 'dart:io';
import 'package:test/test.dart';
import 'package:dart_pdf_reader/dart_pdf_reader.dart';

void main() {
  group('PDF Embedded File Extraction', () {
    test('Extracts embedded files from PDF', () async {
      // Load a test PDF that contains embedded files
      final pdfBytes = await File('test/resources/pdf/sample_with_attachment.pdf').readAsBytes();
      final attachments = await PDFAttachmentExtractor().extractEmbeddedFilesFromPDF(pdfBytes);

      expect(attachments, isNotEmpty);

      // Check that extracted file has a valid name and non-empty content
      final firstAttachment = attachments.first;
      expect(firstAttachment.fileName, isNotNull);
      expect(firstAttachment.bytes, isNotEmpty);

      expect(firstAttachment.fileName, equals('(invoice.xml)'));
    });

    test('Returns empty list when no attachments found', () async {
      // Load a PDF that does NOT have embedded files
      final pdfBytes = await File('test/resources/pdf/641701496.pdf').readAsBytes();
      final attachments = await PDFAttachmentExtractor().extractEmbeddedFilesFromPDF(pdfBytes);

      // Expect no extracted files
      expect(attachments, isEmpty);
    });

    test('Extracts embedded files from zugferd-example', () async {
      // Load a corrupted or invalid PDF file
      final pdfBytes = await File('test/resources/pdf/ZUGFeRD-Example.pdf').readAsBytes();
      final attachments = await PDFAttachmentExtractor().extractEmbeddedFilesFromPDF(pdfBytes);
      final firstAttachment = attachments.first;
      expect(firstAttachment.bytes, isNotEmpty);
    });
  });
}
