import 'dart:typed_data';

class ExtractedPDFAttachment {
  String? decodedContent; // has to be set if xrechnung
  Uint8List bytes;
  String? fileName;
  String? description;

  ExtractedPDFAttachment({
    this.decodedContent,
    required this.bytes,
    this.fileName,
    this.description,
  });
}
