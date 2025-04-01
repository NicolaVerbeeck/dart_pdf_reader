import 'dart:convert';
import 'dart:typed_data';
import '../../dart_pdf_reader.dart';

/// Extracts image  from a PDF.
class PDFAImageExtractor {
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
      // print('Error extracting images from PDF: $e');
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

  Future<ExtractedPDFImage?> _extractImageDataFromXObject(
    PDFDocument doc,
    PDFDocumentCatalog catalog,
    PDFStreamObject xObjectResolved,
    String key,
  ) async {
    try {
      final subtype = xObjectResolved.dictionary.entries[PDFNames.subtype];
      if (subtype is PDFName && subtype.value == 'Image') {
        final resolverRead = await xObjectResolved.read(catalog.resolver);
        final filter = xObjectResolved.dictionary.entries[PDFNames.filter];
        final width = xObjectResolved.dictionary.entries[PDFNames.width].toString();
        final height = xObjectResolved.dictionary.entries[PDFNames.height].toString();
        Map<String, dynamic>? sMaskProperties;
        final length = xObjectResolved.dictionary.entries[PDFNames.length].toString();

        // Check if 'SMask' exists and resolve it if necessary
        final sMask = xObjectResolved.dictionary.entries[PDFNames.sMask];
        if (sMask != null) {
          final sMaskResolved = await doc.resolve(sMask);

          if (sMaskResolved is PDFStreamObject) {
            sMaskProperties = {
              'width': sMaskResolved.dictionary.entries[PDFNames.width]?.toString(),
              'height': sMaskResolved.dictionary.entries[PDFNames.height]?.toString(),
              'byte': await sMaskResolved.read(catalog.resolver)
            };
          }
        }
        final colorSpace = xObjectResolved.dictionary.entries[PDFNames.colorSpace].toString();
        final bitsPerComponent = xObjectResolved.dictionary.entries[PDFNames.bitsPerComponent].toString();
        if (filter is PDFName) {
          final filterValue = filter.value.toString();

          switch (filter.value) {
            case 'FlateDecode':
              return await _extractImageAsBase64(resolverRead, 'png', width, height, sMaskProperties, colorSpace, bitsPerComponent, filterValue, length, key);
            case 'DCTDecode':
              return await _extractImageAsBase64(resolverRead, 'jpg', width, height, sMaskProperties, colorSpace, bitsPerComponent, filterValue, length, key);
            case 'JPXDecode':
              return await _extractImageAsBase64(resolverRead, 'jp2', width, height, sMaskProperties, colorSpace, bitsPerComponent, filterValue, length, key);
            default:
            // print('Unsupported filter: ${filter.value}');
          }
        }
      }
    } catch (e) {
      // print('Error extracting image data from XObject: $e');
    }
    return null;
  }

  Future<ExtractedPDFImage?> _extractImageAsBase64(Uint8List resolverRead, String format, String? width, String? height, Map<String, dynamic>? sMask, String? colorSpace, String? bitsPerComponent,
      String? filter, String? length, String key) async {
    // Read the stream data from the XObject and convert it to a base64 string.
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
}
