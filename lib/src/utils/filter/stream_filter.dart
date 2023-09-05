import 'dart:io';
import 'dart:typed_data';

import 'package:dart_pdf_reader/dart_pdf_reader.dart';
import 'package:dart_pdf_reader/src/utils/filter/direct_byte_stream.dart';
import 'package:dart_pdf_reader/src/utils/list_extensions.dart';

part 'ascii_85_decode_filter.dart';
part 'ascii_hex_decode_filter.dart';
part 'flate_decode_filter.dart';
part 'lzw_decode_filter.dart';
part 'run_length_decode_filter.dart';

sealed class StreamFilter {
  factory StreamFilter(PDFName name) {
    switch (name.value) {
      case 'ASCIIHexDecode':
      case 'AHx':
        return const ASCIIHexDecodeFilter._();
      case 'FlateDecode':
      case 'FL':
        return const FlateDecodeFilter._();
      case 'ASCII85Decode':
      case 'A85':
        return const ASCII85DecodeFilter._();
      case 'LZWDecode':
        return const LZWDecodeFilter._();
      case 'RunLengthDecode':
        return const RunLengthDecodeFilter._();
      case 'DCTDecode':
      case 'JPXDecode':
        return const _NoOpDecodeFilter._();
      default:
        throw UnimplementedError('Unknown/unimplemented filter: $name');
    }
  }

  const StreamFilter._();

  Uint8List decode(
    Uint8List bytes,
    PDFObject? params,
    PDFDictionary streamDictionary,
  );
}

class _NoOpDecodeFilter extends StreamFilter {
  const _NoOpDecodeFilter._() : super._();

  @override
  Uint8List decode(
    Uint8List bytes,
    PDFObject? params,
    PDFDictionary streamDictionary,
  ) {
    return bytes;
  }
}
