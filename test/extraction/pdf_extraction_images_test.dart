import 'dart:io';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:dart_pdf_reader/dart_pdf_reader.dart';

void main() {
  group('PDF Embedded File Extraction', () {
    test('PDF with image Example 2', () async {
      final file = File('test/resources/pdf/pdf_with3_images_in_1page.pdf');
      final stream = ByteStream(file.readAsBytesSync());
      final extracted = await PDFImageExtractor().extractImagesFromPDFStream(stream);
      expect(extracted, isNotNull);
      expect(extracted.first.b64image, isNotNull);
      expect(extracted.first.width, isNotNull);
      expect(extracted.first.fileName, isNotNull);
      expect(extracted.first.colorSpace, isNotNull);
      expect(extracted.last.sMask, isNotNull);
    });

    test('PDF with image Example 4', () async {
      final file = File('test/resources/pdf/pdf_barcode.pdf');
      final stream = ByteStream(file.readAsBytesSync());
      final extracted = await PDFImageExtractor().extractImagesFromPDFStream(stream);
      final firstImage = extracted.first;

      expect(extracted, isNotNull);
      expect(extracted.first.bytes, isA<Uint8List>());
      expect(firstImage.b64image.startsWith('/9j/'), isTrue);
      expect(extracted.first.colorSpace, isNotNull);
      expect(extracted.first.b64image, isNotNull);
      expect(extracted.first.width, isNotNull);
      expect(extracted.first.fileName, isNotNull);
      expect(extracted.first.filter, isNotNull);
    });

    test('PDF with image Example china airlines', () async {
      final file = File('test/resources/pdf/china_airlines_boardingPass.pdf');
      final stream = ByteStream(file.readAsBytesSync());
      final extracted = await PDFImageExtractor().extractImagesFromPDFStream(stream);

      expect(extracted, isNotNull);
      expect(extracted.first.bytes, isA<Uint8List>());
      expect(extracted.first.colorSpace, isNotNull);
      expect(extracted.first.b64image, isNotNull);
      expect(extracted.first.width, isNotNull);
      expect(extracted.first.fileName, isNotNull);
      expect(extracted.first.filter, isNotNull);
    });

    test('PDF with image Example 3', () async {
      final file = File('test/resources/pdf/testingbarcode.pdf');
      final stream = ByteStream(file.readAsBytesSync());
      final extracted = await PDFImageExtractor().extractImagesFromPDFStream(stream);
      expect(extracted, isNotNull);
      expect(extracted.first.b64image, isNotNull);
      expect(extracted.first.width, isNotNull);
      expect(extracted.first.fileName, isNotNull);
      expect(extracted.first.colorSpace, isNotNull);
      expect(extracted.first.bytes, isA<Uint8List>());
    });
  });
}
