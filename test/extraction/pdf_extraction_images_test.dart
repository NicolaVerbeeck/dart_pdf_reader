import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:dart_pdf_reader/dart_pdf_reader.dart';
import '../utils/test_utils.dart';

void main() {
  group('PDF Embedded Image Extraction', () {
    test('Test image filter extraction exmaple 1', () async {
      final pdfBytes = await File('test/resources/pdf/641701496.pdf').readAsBytes();
      final extracted = await PDFImageExtractor().extractImagesFromPDF(pdfBytes);
      expect(extracted.length, equals(3), reason: 'Expected exactly 3 images extracted');
      expect(extracted, isNotNull);

      final img1 = extracted.first;
      final bytes0 = base64Decode(img1.b64image);

      final expectedBytes1 = await File('test/resources/images/logo_2.jpeg').readAsBytes();
      expect(bytes0.take(10), equals(expectedBytes1.take(10)), reason: 'First bytes should match');

      expect(isJpeg(bytes0), isTrue, reason: 'Image 0 should be JPEG');
      expect(img1.width, equals(2067));
      expect(img1.height, equals(161));
      expect(bytes0.length, equals(67566), reason: 'Image 0 byte‐length');
      expect(img1.length, equals(67566), reason: 'Image 0 dict Length');

      final img3 = extracted[2];
      final actualBytes3 = base64Decode(img3.b64image);
      final expectedBytes3 = await File('test/resources/images/qr_code.png').readAsBytes();
      expect(actualBytes3.take(20), expectedBytes3.take(20), reason: 'First bytes should match');

  
      final img2 = extracted.last;
      final bytes2 = base64Decode(img2.b64image);
      expect(isPng(bytes2), isTrue, reason: 'Image 2 should be PNG');
      expect(img2.width, equals(413));
      expect(img2.height, equals(413));
    });

    test('Extracted images match expected parameters', () async {
      final file = File('test/resources/pdf/pdf_with3_images_in_1page.pdf');
      final stream = ByteStream(await file.readAsBytes());
      final extracted = await PDFImageExtractor().extractImagesFromPDFStream(stream);
      expect(extracted.length, equals(3), reason: 'Expected exactly 3 images extracted');

      final img1 = extracted.first;
      final bytes0 = base64Decode(img1.b64image);
      expect(isJpeg(bytes0), isTrue, reason: 'Image 0 should be JPEG');
      expect(img1.width, equals(615));
      expect(img1.height, equals(527));
      expect(bytes0.length, equals(57177), reason: 'Image 0 byte‐length');
      expect(img1.length, equals(57177), reason: 'Image 0 dict Length');

      final expectedBytes1 = await File('test/resources/images/barcode_01.jpeg').readAsBytes();
      expect(bytes0.take(12), equals(expectedBytes1.take(12)), reason: 'First bytes should match');

      final img2 = extracted.last;
      final bytes2 = base64Decode(img2.b64image);
      expect(isPng(bytes2), isTrue, reason: 'Image 2 should be PNG');
      expect(img2.width, equals(600));
      expect(img2.height, equals(600));

      final expectedBytes2 = await File('test/resources/images/barcode_03.png').readAsBytes();
      expect(bytes2.take(12), equals(expectedBytes2.take(12)), reason: 'First bytes should match');

      final sMaskBytes = base64Decode(img2.sMask!['bytes'].toString());
      expect(isPng(sMaskBytes), isTrue, reason: 'Image 2 SMask should be PNG');
    });

    test('PDF with image Example 4', () async {
      final file = File('test/resources/pdf/pdf_barcode.pdf');
      final stream = ByteStream(file.readAsBytesSync());
      final extracted = await PDFImageExtractor().extractImagesFromPDFStream(stream);
      expect(extracted.length, equals(2), reason: 'Expected exactly 2 images extracted');
      expect(extracted, isNotNull);

      final img1 = extracted.first;
      final bytes0 = base64Decode(img1.b64image);
      expect(isJpeg(bytes0), isTrue, reason: 'Image 0 should be JPEG');
      expect(img1.width, equals(1936));
      expect(img1.height, equals(1452));


      final expectedBytes1 = await File('test/resources/images/qr_code_1.png').readAsBytes();
      expect(bytes0.take(12), equals(expectedBytes1.take(12)), reason: 'First bytes should match');

      final img2 = extracted.last;
      final bytes2 = base64Decode(img2.b64image);
      expect(isJpeg(bytes2), isTrue, reason: 'Image 2 should be JPEG');
      expect(img2.width, equals(500));
      expect(img2.height, equals(500));
    });

    test('PDF with image Example china airlines', () async {
      final file = File('test/resources/pdf/china_airlines_boardingPass.pdf');
      final stream = ByteStream(file.readAsBytesSync());
      final extracted = await PDFImageExtractor().extractImagesFromPDFStream(stream);
      final expectedBytes1 = await File('test/resources/images/air_china_01.png').readAsBytes();

      expect(extracted.length, equals(15), reason: 'Expected exactly 15 images extracted');
      final bytes0 = base64Decode(extracted.first.b64image);
      expect(bytes0.take(15), equals(expectedBytes1.take(15)), reason: 'First bytes should match');

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

      final expectedBytes1 = await File('test/resources/images/test_barcode_01.jpeg').readAsBytes();

      expect(extracted.length, equals(2), reason: 'Expected exactly 2 images extracted');
      final bytes0 = base64Decode(extracted.first.b64image);
      expect(bytes0.take(13), equals(expectedBytes1.take(13)), reason: 'First bytes should match');

      expect(extracted, isNotNull);
      expect(extracted.first.b64image, isNotNull);
      expect(extracted.first.width, isNotNull);
      expect(extracted.first.fileName, isNotNull);
      expect(extracted.first.colorSpace, isNotNull);
      expect(extracted.first.bytes, isA<Uint8List>());
    });

    test('extractImagesFromPDFStream returns empty list when pagesRef is not a reference', () async {
      final fakeStream = ByteStream(Uint8List.fromList([]));
      final extractor = PDFImageExtractor();

      final result = await extractor.extractImagesFromPDFStream(fakeStream);

      expect(result, isEmpty);
    });

    test('extractImagesFromPDFStream returns empty list on error', () async {
      final extractor = PDFImageExtractor();

      // simulate corrupted input
      final bytes = Uint8List.fromList([0x00]);

      final result = await extractor.extractImagesFromPDF(bytes);

      expect(result, isEmpty);
    });
  });
}
