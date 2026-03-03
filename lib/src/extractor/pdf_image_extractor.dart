import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../../dart_pdf_reader.dart';

/// Extracts image  from a PDF.
class PDFImageExtractor {
  Future<List<ExtractedPDFImage>> extractImagesFromPDF(Uint8List bytes) async {
    return await extractImagesFromPDFStream(ByteStream(bytes));
  }

  Future<List<ExtractedPDFImage>> extractImagesFromPDFStream(ByteStream stream) async {
    try {
      final doc = await PDFParser(stream).parse();

      final catalog = await doc.catalog;

      final pagesRef = catalog.dictionary.entries[PDFNames.pages];

      if (pagesRef is PDFObjectReference) {
        final pagesResolved = await doc.resolve(pagesRef);
        if (pagesResolved is PDFDictionary) {
          return await extractImagesFromPages(doc, catalog, pagesResolved);
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<ExtractedPDFImage>> extractImagesFromPages(
    PDFDocument doc,
    PDFDocumentCatalog catalog,
    PDFDictionary pagesResolved,
  ) async {
    final images = <ExtractedPDFImage>[];

    // Check if resources exist
    final resources = pagesResolved.entries[PDFNames.resources];
    if (resources != null) {
      // If resources exists, resolve it to extract image
      final resourcesResolved = await doc.resolve(resources);
      final resourceImages = await extractImagesFromResources(doc, catalog, resourcesResolved);
      images.addAll(resourceImages);
    }
    // If images in resources doesnot exist, go through kids->resources to extract image
    if (images.isEmpty) {
      final kidsImages = await extractImagesFromKids(doc, catalog, pagesResolved);
      images.addAll(kidsImages);
    }
    return images;
  }

  Future<List<ExtractedPDFImage>> extractImagesFromKids(
    PDFDocument doc,
    PDFDocumentCatalog catalog,
    PDFDictionary pagesResolved,
  ) async {
    final images = <ExtractedPDFImage>[];
    final kids = pagesResolved.entries[PDFNames.kids];
    if (kids is PDFArray && kids.isNotEmpty) {
      for (final kidArray in kids) {
        if (kidArray is PDFObjectReference) {
          final kidsResolved = await doc.resolve(kidArray);
          if (kidsResolved is PDFDictionary) {
            final resources = kidsResolved.entries[PDFNames.resources];
            final pageImages = await extractImagesFromResources(doc, catalog, resources);
            images.addAll(pageImages);
          }
        }
      }
    }
    return images;
  }

  Future<List<ExtractedPDFImage>> extractImagesFromResources(
    PDFDocument doc,
    PDFDocumentCatalog catalog,
    PDFObject? resources,
  ) async {
    final images = <ExtractedPDFImage>[];

    if (resources case final PDFDictionary xObjectsDictonary) {
      final xObjects = xObjectsDictonary.entries[PDFNames.xObject];
      if (xObjects is PDFDictionary) {
        for (final entry in xObjects.entries.entries) {
          final xObjectValue = entry.value;
          final xObjectKey = entry.key.value;
          if (xObjectValue is PDFObjectReference) {
            final xObjectResolved = await doc.resolve(xObjectValue);
            if (xObjectResolved is PDFStreamObject) {
              final image = await _extractImageDataFromXObject(doc, catalog, xObjectResolved, xObjectKey);
              if (image != null) {
                images.add(image);
              }
            }
          }
        }
      }
    }
    return images;
  }

  /// Extracts an image from a PDF XObject stream and returns it as PNG or JPEG bytes.
  /// Handles FlateDecode (DeviceGray 1/8bits per pixel and DeviceRGB 8bits per pixel) and DCTDecode (JPEG).
  /// Automatically unpacks 1bits per pixel grayscale images/masks. Resolves references as needed.
  Future<ExtractedPDFImage?> _extractImageDataFromXObject(
    PDFDocument doc,
    PDFDocumentCatalog catalog,
    PDFStreamObject xObjectResolved,
    String key,
  ) async {
    try {
      final subtype = xObjectResolved.dictionary.entries[PDFNames.subtype];
      if (subtype is PDFName && subtype.value == 'Image') {
        final filter = xObjectResolved.dictionary.entries[PDFNames.filter];
        final w = await getIntFromPDFDict(doc, xObjectResolved.dictionary.entries[PDFNames.width]);
        final h = await getIntFromPDFDict(doc, xObjectResolved.dictionary.entries[PDFNames.height]);
        final bitsPerComponent = await getIntFromPDFDict(doc, xObjectResolved.dictionary.entries[PDFNames.bitsPerComponent]);
        final length = await getIntFromPDFDict(doc, xObjectResolved.dictionary.entries[PDFNames.length]);
        final colorSpace = xObjectResolved.dictionary.entries[PDFNames.colorSpace]?.toString();

        if (filter is PDFName) {
          final filterValue = filter.value.toString();
          var resolverRead = await xObjectResolved.read(catalog.resolver);

          switch (filter.value) {
            case 'FlateDecode':
              if (bitsPerComponent == 1 && colorSpace == '/DeviceGray') {
                resolverRead = _convertBitsToBytes(resolverRead, w, h);
              }

              Map<String, dynamic>? sMaskProperties;
              final sMask = xObjectResolved.dictionary.entries[PDFNames.sMask];
              if (sMask != null) {
                final sMaskResolved = await doc.resolve(sMask);
                if (sMaskResolved is PDFStreamObject) {
                  final sMaskWidth = await getIntFromPDFDict(doc, sMaskResolved.dictionary.entries[PDFNames.width]);
                  final sMaskHeight = await getIntFromPDFDict(doc, sMaskResolved.dictionary.entries[PDFNames.height]);
                  final sMaskBitsPerComponent = await getIntFromPDFDict(doc, sMaskResolved.dictionary.entries[PDFNames.bitsPerComponent]);

                  var sMaskBytes = await sMaskResolved.read(catalog.resolver);

                  if (sMaskBitsPerComponent == 1) {
                    sMaskBytes = _convertBitsToBytes(sMaskBytes, sMaskWidth, sMaskHeight);
                  }

                  final sMaskPng = convertRawToPng(sMaskBytes, sMaskWidth, sMaskHeight, isGray: true);

                  sMaskProperties = {
                    'width': sMaskWidth,
                    'height': sMaskHeight,
                    'bytes': sMaskPng != null ? base64Encode(sMaskPng) : null,
                  };
                }
              }

              final pngBytes = convertRawToPng(resolverRead, w, h, isGray: (colorSpace == '/DeviceGray'));
              if (pngBytes != null) {
                return await _extractImageAsBase64(pngBytes, 'png', w, h, sMaskProperties, colorSpace, bitsPerComponent, filterValue, length, key);
              }
              return null;

            case 'DCTDecode':
              return await _extractImageAsBase64(resolverRead, 'jpg', w, h, null, colorSpace, bitsPerComponent, filterValue, length, key);
            default:
              return null;
          }
        }
      }
    } catch (e) {
      throw Exception('Error extracting image data from XObject: $e');
    }
    return null;
  }

  Future<ExtractedPDFImage?> _extractImageAsBase64(
      Uint8List resolverRead, String format, int? width, int? height, Map<String, dynamic>? sMask, String? colorSpace, int? bitsPerComponent, String? filter, int? length, String key) async {
    final filename = '$key.$format';

    return ExtractedPDFImage(
        b64image: base64Encode(resolverRead),
        bytes: resolverRead,
        fileName: filename,
        height: height,
        width: width,
        sMask: sMask,
        colorSpace: colorSpace,
        bitsPerComponent: bitsPerComponent,
        filter: filter,
        length: length);
  }

  /// Converts raw bytes (8-bit, uint8) to PNG bytes.
  /// You must provide [width] and [height].
  Uint8List? convertRawToPng(Uint8List? rawBytes, int width, int height, {bool isGray = false}) {
    if (rawBytes == null) return null;
    if (isGray) {
      final expectedLength = width * height;
      if (rawBytes.length != expectedLength) {
        return null;
      }
      final rgbBytes = Uint8List(expectedLength * 3);
      for (var i = 0; i < expectedLength; i++) {
        final v = rawBytes[i];
        rgbBytes[i * 3] = v;
        rgbBytes[i * 3 + 1] = v;
        rgbBytes[i * 3 + 2] = v;
      }
      final dartImage = img.Image.fromBytes(
        width: width,
        height: height,
        bytes: rgbBytes.buffer,
        numChannels: 3,
        order: img.ChannelOrder.rgb,
      );
      return Uint8List.fromList(img.PngEncoder().encode(dartImage));
    } else {
      final expectedLength = width * height * 3;
      if (rawBytes.length != expectedLength) {
        return null;
      }
      final dartImage = img.Image.fromBytes(
        width: width,
        height: height,
        bytes: rawBytes.buffer,
        numChannels: 3,
        order: img.ChannelOrder.rgb,
      );
      return Uint8List.fromList(img.PngEncoder().encode(dartImage));
    }
  }

  // --- Helper: Unpack 1bpp into 8bpp grayscale ---
  Uint8List _convertBitsToBytes(Uint8List input, int width, int height) {
    final output = Uint8List(width * height);
    var byteIndex = 0, bitIndex = 7;
    for (var i = 0; i < output.length; i++) {
      if (bitIndex < 0) {
        bitIndex = 7;
        byteIndex++;
      }
      if (byteIndex >= input.length) break;
      output[i] = ((input[byteIndex] >> bitIndex--) & 1) == 1 ? 255 : 0;
    }
    return output;
  }

  // Use this for width, height, bitsPerComponent, etc.
  Future<int> getIntFromPDFDict(
    PDFDocument doc,
    dynamic value,
  ) async {
    // If it's a reference, resolve it recursively
    while (value is PDFObjectReference) {
      value = await doc.resolve(value);
    }
    if (value == null) return 0;
    // If it's a number type
    if (value is PDFNumber) return value.toInt();
    // Try parsing from string (covers int and numeric strings)
    return int.tryParse(value.toString()) ?? 0;
  }
}
