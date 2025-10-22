import 'dart:convert';
import 'dart:typed_data';
import '../../dart_pdf_reader.dart';

/// Extracts embedded file attachments from a PDF.
class PDFAttachmentExtractor {
  /// Extracts files from a PDF given its byte data.
  Future<List<ExtractedPDFAttachment>> extractEmbeddedFilesFromPDF(Uint8List bytes) async {
    return extractEmbeddedFilesFromPDFStream(ByteStream(bytes));
  }

  /// Extracts files from a PDF stream.
  Future<List<ExtractedPDFAttachment>> extractEmbeddedFilesFromPDFStream(ByteStream stream) async {
    final doc = await PDFParser(stream).parse();
    final catalog = await doc.catalog;
    final dict = catalog.dictionary;

    final attachments = <ExtractedPDFAttachment>[];

    // Extract from /AF array
    if (dict.entries[PDFNames.af] case final PDFObjectReference afRef) {
      final afResolved = await doc.resolve(afRef);
      if (afResolved is PDFArray) {
        attachments.addAll(await extractFilesFromAFArray(afResolved, doc, catalog));
      }
    } else if (dict.entries[PDFNames.af] case final PDFArray afResolved) {
      attachments.addAll(await extractFilesFromAFArray(afResolved, doc, catalog));
    }

    // Extract from /EmbeddedFiles/Names
    if (dict.entries[PDFNames.names] case final PDFDictionary namesDict) {
      if (namesDict.entries[PDFNames.embeddedFiles] case final PDFDictionary embeddedFilesDict) {
        if (embeddedFilesDict.entries[PDFNames.names] case final PDFArray namesArray) {
          attachments.addAll(await extractFilesFromNamesArray(namesArray, doc, catalog));
        }
      }
    }

    //return attachments;

    /// Returns a list of attachments with duplicate actual content (decoded from bytes) removed.
    return {for (var att in attachments) utf8.decode(att.bytes): att}.values.toList();
  }

  /// Extracts files from the `/AF` array.
  Future<List<ExtractedPDFAttachment>> extractFilesFromAFArray(PDFArray afResolved, PDFDocument doc, PDFDocumentCatalog catalog) async {
    final attachments = <ExtractedPDFAttachment>[];
    for (var ref in afResolved.whereType<PDFObjectReference>()) {
      final dictUnderAF = await doc.resolve(ref);

      if (dictUnderAF is PDFDictionary) {
        final ef = dictUnderAF.entries[PDFNames.ef];
        if (ef is PDFDictionary) {
          final attachment = await extractFilesFromEF(ef, doc, catalog, dictUnderAF);
          if (attachment != null) {
            attachments.add(attachment);
          }
        } else if (ef is PDFObjectReference) {
          final efResolved = await doc.resolve(ef);
          if (efResolved is PDFDictionary) {
            final attachment = await extractFilesFromEF(efResolved, doc, catalog, dictUnderAF);
            if (attachment != null) {
              attachments.add(attachment);
            }
          }
        }
      }
    }
    return attachments;
  }

  /// Extracts files from the `/EmbeddedFiles/Names` dictionary.
  Future<List<ExtractedPDFAttachment>> extractFilesFromNamesArray(PDFArray namesArray, PDFDocument doc, PDFDocumentCatalog catalog) async {
    final attachments = <ExtractedPDFAttachment>[];
    for (var i = 0; i < namesArray.length - 1; i += 2) {
      final fileNameObj = namesArray[i];
      final fileSpecRef = namesArray[i + 1];
      final fileSpec = await doc.resolve(fileSpecRef);
      if (fileSpec is PDFDictionary) {
        final ef = fileSpec.entries[PDFNames.ef];
        if (ef is PDFDictionary) {
          final attachment = await extractFilesFromEF(ef, doc, catalog, fileSpec);
          if (attachment != null) {
            attachment.fileName ??= fileNameObj.toString();
            attachments.add(attachment);
          }
        }
      }
    }
    return attachments;
  }

  /// Extracts file data from an `/EF` dictionary.
  Future<ExtractedPDFAttachment?> extractFilesFromEF(PDFDictionary ef, PDFDocument doc, PDFDocumentCatalog catalog, PDFDictionary dictUnderAF) async {
    if (ef.entries[PDFNames.f] case final PDFObjectReference efFRef) {
      final efF = await doc.resolve(efFRef);

      if (efF is PDFStreamObject) {
        final resolverRead = await efF.read(catalog.resolver);
        String? attachmentData;
        try {
          attachmentData = utf8.decode(resolverRead);
        } catch (_) {}

        String? fileName;
        if (dictUnderAF.entries[PDFNames.f] case final PDFLiteralString fileNameLiteral) {
          fileName = fileNameLiteral.asString();
        }

        String? description;
        if (dictUnderAF.entries[PDFNames.desc] case final PDFLiteralString descLiteral) {
          description = descLiteral.asString();
        }
        return ExtractedPDFAttachment(
          decodedContent: attachmentData,
          bytes: resolverRead,
          fileName: fileName,
          description: description,
        );
      }
    }

    return null;
  }
}
