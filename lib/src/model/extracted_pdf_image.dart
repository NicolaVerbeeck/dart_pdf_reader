import 'dart:typed_data';

/// Represents an image object extracted from a PDF document.
/// This class stores both the binary and Base64-encoded versions of the image,
/// along with metadata such as dimensions, color space, and encoding details.
class ExtractedPDFImage {
  final String b64image; // The Base64-encoded representation of the image bytes.
  final Uint8List bytes; // The raw image data as bytes.
  final String? fileName; // The original file name of the image, if available.
  final int? width; // The image width in pixels, if available.
  final int? height; // The image height in pixels, if available.
  final Map<String, dynamic>? sMask;  // The soft mask (`/SMask`) dictionary, if the image contains transparency information.
  final String? colorSpace; // The color space of the image (e.g. `/DeviceRGB`, `/DeviceGray`).
  final int? bitsPerComponent; // The number of bits used to represent each color component.
  final String? filter; // The applied image compression filter (e.g. `/DCTDecode`, `/FlateDecode`, `/JPXDecode`).
  final int? length; // The declared length of the image stream in bytes.

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
