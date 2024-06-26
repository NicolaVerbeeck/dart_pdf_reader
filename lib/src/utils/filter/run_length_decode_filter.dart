part of 'stream_filter.dart';

class RunLengthDecodeFilter extends StreamFilter {
  const RunLengthDecodeFilter._() : super._();

  @override
  Uint8List decode(
    Uint8List bytes,
    PDFObject? params,
    PDFDictionary streamDictionary,
  ) {
    final out = ByteOutputStream(bytes.length);

    for (var i = 0; i < bytes.length; ++i) {
      final n = bytes[i];
      if (n == 128) {
        break;
      }
      if ((n & 0x80) == 0) {
        final bytesToCopy = n + 1;
        out.writeAll(Uint8List.view(
            bytes.buffer, bytes.offsetInBytes + i + 1, bytesToCopy));
        i += bytesToCopy;
      } else {
        ++i;
        for (var j = 0; j < 257 - (n & 0xFF); ++j) {
          out.write(bytes[i]);
        }
      }
    }

    return out.getBytes();
  }
}
