import 'dart:io';

import 'package:dart_pdf_reader/dart_pdf_reader.dart';
import 'package:dart_pdf_reader/src/utils/filter/direct_byte_stream.dart';

part 'ascii_hex_decode_filter.dart';
part 'flate_decode_filter.dart';

sealed class StreamFilter {
  factory StreamFilter(PDFName name) {
    switch (name.value) {
      case 'ASCIIHexDecode':
      case 'AHx':
        return const ASCIIHexDecodeFilter._();
      case 'FlateDecode':
      case 'FL':
        return const FlateDecodeFilter._();
      default:
        throw UnimplementedError('Unknown filter: $name');
    }
  }

  const StreamFilter._();

  List<int> decode(
    List<int> bytes,
    PDFObject? params,
    PDFDictionary streamDictionary,
  );
}
