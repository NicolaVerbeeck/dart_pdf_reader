import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:dart_pdf_reader/dart_pdf_reader.dart';

void main() {
  group('PDF Embedded File Extraction', () {
    test('Extracts embedded XML file from PDF and checks content', () async {
      final pdfBytes = await File('test/resources/pdf/sample_with_attachment.pdf').readAsBytes();
      final attachments = await PDFAttachmentExtractor().extractEmbeddedFilesFromPDF(pdfBytes);
      final expectedXml = File('test/resources/attachments/invoice.xml');
      final firstAttachment = attachments.first;
      final expectedXmlBytes = await expectedXml.readAsBytes();
      final expectedXmlContent = await expectedXml.readAsString();

      expect(attachments, isNotEmpty);
      expect(attachments.length, equals(1));

      expect(firstAttachment.fileName, equals('invoice.xml'));

      expect(firstAttachment.bytes, equals(expectedXmlBytes));
      expect(firstAttachment.decodedContent, equals(expectedXmlContent));
    });
    test('PDF Würth Example (normalized byte match)', () async {
      final file = File('test/resources/pdf/641701496.pdf');
      final stream = ByteStream(file.readAsBytesSync());
      final extracted = await PDFAttachmentExtractor().extractEmbeddedFilesFromPDFStream(stream);
      final firstAttachment = extracted.last;
      final expectedContent = await File('test/resources/attachments/factur-x.xml').readAsString();
      final extractedContent = firstAttachment.decodedContent!;
      String normalize(String content) => content.replaceAll('\t', '').replaceAll('\n', '').replaceAll('\r', '').trim();
      final normalizedExpected = normalize(expectedContent);
      final normalizedExtracted = normalize(extractedContent);

      expect(extracted, isNotEmpty);
      expect(extracted.length, equals(1));

      expect(firstAttachment.fileName, equals('factur-x.xml'));

      expect(utf8.encode(normalizedExtracted), utf8.encode(normalizedExpected));
      expect(normalizedExtracted, equals(normalizedExpected));
    });

    test('Extracts embedded files from zugferd-example', () async {
      // Load a corrupted or invalid PDF file
      final pdfBytes = await File('test/resources/pdf/ZUGFeRD-Example.pdf').readAsBytes();
      final attachments = await PDFAttachmentExtractor().extractEmbeddedFilesFromPDF(pdfBytes);
      final firstAttachment = attachments.first;
      final expectedContent = await File('test/resources/attachments/factur-x-1.xml').readAsString();
      final expectedJsonBytes = await File('test/resources/attachments/factur-x-1.xml').readAsBytes();
      String normalize(String content) => content.replaceAll('\t', '').replaceAll('\n', '').replaceAll('\r', '').trim();
      final normalizedExpected = normalize(expectedContent);
      final normalizedExtracted = normalize(firstAttachment.decodedContent!);

      expect(attachments, isNotEmpty);
      expect(attachments.length, equals(1));
      expect(firstAttachment.fileName, equals('factur-x.xml'));

      expect(normalizedExtracted, equals(normalizedExpected));
      expect(firstAttachment.bytes, equals(expectedJsonBytes));
    });

    test('Extracts JSON file embedded in PDF', () async {
      final pdfBytes = await File('test/resources/pdf/sample_pdf_with_json_attachments.pdf').readAsBytes();
      final attachments = await PDFAttachmentExtractor().extractEmbeddedFilesFromPDF(pdfBytes);
      final expectedJsonBytes = await File('test/resources/attachments/config.json').readAsBytes();
      final firstAttachment = attachments.first;

      expect(attachments, isNotEmpty);
      expect(attachments.length, equals(1));

      expect(firstAttachment.fileName, equals('config.json'));
      expect(firstAttachment.bytes, equals(expectedJsonBytes));
    });
  });
}
