import 'dart:typed_data';

class ExtractedPDFImage {
  final String b64image;
  final Uint8List bytes;
  final String? fileName;
  final String? width;
  final String? height;
  final Map<String, dynamic>? sMask;
  final String? colorSpace;
  final String? bitsPerComponent;
  final String? filter;
  final String? length;

  ExtractedPDFImage({
    required this.b64image,
    required this.bytes,
    this.fileName,
    this.width,
    this.height,
    this.sMask,
    this.colorSpace,
    this.bitsPerComponent,
    this.filter,
    this.length,
  });
}
