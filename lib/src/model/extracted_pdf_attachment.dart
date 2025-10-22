import 'dart:typed_data';

class ExtractedPDFAttachment {
  String? decodedContent; // Contains the UTF-8 decoded version of [bytes], if attachment was uft8 decodable.
  Uint8List bytes; // The raw binary data of the attachment.
  String? fileName; // The original file name of the attachment, if available.
  String? description; // An optional description of the attachment.

  ExtractedPDFAttachment({
    this.decodedContent,
    required this.bytes,
    this.fileName,
    this.description,
  });
}
