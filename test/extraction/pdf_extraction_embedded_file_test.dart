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

      expect(firstAttachment.fileName, equals('invoice.xml'));
    });

    test('PDF Würth Example', () async {
      final file = File('test/resources/pdf/641701496.pdf');
      final stream = ByteStream(file.readAsBytesSync());
      final extracted = await PDFAttachmentExtractor().extractEmbeddedFilesFromPDFStream(stream);
      expect(extracted, isNotNull);
      expect(extracted.first.description, isNotNull);
      expect(extracted.first.fileName, isNotNull);
    });

    test('Extracts embedded files from zugferd-example', () async {
      // Load a corrupted or invalid PDF file
      final pdfBytes = await File('test/resources/pdf/ZUGFeRD-Example.pdf').readAsBytes();
      final attachments = await PDFAttachmentExtractor().extractEmbeddedFilesFromPDF(pdfBytes);
      final firstAttachment = attachments.first;
      expect(firstAttachment.bytes, isNotEmpty);
    });

    test('Extracts json file embedded files from PDF', () async {
      // Load a test PDF that contains json embedded files
      final pdfBytes = await File('test/resources/pdf/sample_pdf_with_json_attachments.pdf').readAsBytes();
      final attachments = await PDFAttachmentExtractor().extractEmbeddedFilesFromPDF(pdfBytes);

      expect(attachments, isNotEmpty);

      const expectedFileNames = 'config.json';
      final firstAttachment = attachments.first;
      expect(firstAttachment.fileName, isNotNull);
      expect(firstAttachment.bytes, isNotEmpty);

      expect(firstAttachment.fileName, expectedFileNames);
    });
  });
}
