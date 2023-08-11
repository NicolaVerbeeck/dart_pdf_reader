part of 'stream_filter.dart';

class ASCIIHexDecodeFilter extends StreamFilter {
  const ASCIIHexDecodeFilter._() : super._();

  @override
  Uint8List decode(
    Uint8List bytes,
    PDFObject? params,
    PDFDictionary streamDictionary,
  ) {
    final out = ByteOutputStream(bytes.length);
    var first = true;
    int n1 = 0;
    for (int k = 0; k < bytes.length; ++k) {
      int ch = bytes[k] & 0xff;
      if (ch == 0x3E) {
        break;
      }
      if (_isWhitespace(ch)) {
        continue;
      }
      int n = _getHex(ch);
      if (n == -1) {
        throw ParseException('Illegal character in ASCIIHexDecode stream');
      }
      if (first) {
        n1 = n;
      } else {
        out.write(((n1 << 4) + n));
      }
      first = !first;
    }
    if (!first) {
      out.write((n1 << 4));
    }
    return out.getBytes();
  }
}

int _getHex(int v) {
  if (v >= 0x30 && v <= 0x39) return v - 0x30;
  if (v >= 0x41 && v <= 0x46) return v - 0x41 + 10;
  if (v >= 0x61 && v <= 0x66) return v - 0x61 + 10;
  return -1;
}

bool _isWhitespace(int ch) {
  return ch == 0 || ch == 9 || ch == 10 || ch == 12 || ch == 13 || ch == 32;
}
