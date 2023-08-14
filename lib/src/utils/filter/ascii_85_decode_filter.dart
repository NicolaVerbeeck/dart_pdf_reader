part of 'stream_filter.dart';

class ASCII85DecodeFilter extends StreamFilter {
  const ASCII85DecodeFilter._() : super._();

  @override
  Uint8List decode(
    Uint8List bytes,
    PDFObject? params,
    PDFDictionary streamDictionary,
  ) {
    final out = ByteOutputStream((bytes.length ~/ 5) * 4);

    int state = 0;
    final chn = Uint8List(5);
    for (int k = 0; k < bytes.length; ++k) {
      int ch = bytes[k] & 0xff;
      if (ch == 0x7E) {
        break;
      }
      if (_isWhitespace(ch)) {
        continue;
      }
      if (ch == 0x7A && state == 0) {
        out.write(0);
        out.write(0);
        out.write(0);
        out.write(0);
        continue;
      }
      if (ch < 0x21 || ch > 0x75) {
        throw ParseException('Illegal character in ASCII85Decode stream');
      }
      chn[state] = ch - 0x21;
      ++state;
      if (state == 5) {
        state = 0;
        int r = 0;
        for (int j = 0; j < 5; ++j) {
          r = r * 85 + chn[j];
        }
        out.write((r >> 24) & 0xFF);
        out.write((r >> 16) & 0xFF);
        out.write((r >> 8) & 0xFF);
        out.write(r & 0xFF);
      }
    }
    if (state == 2) {
      int r = chn[0] * 85 * 85 * 85 * 85 +
          chn[1] * 85 * 85 * 85 +
          85 * 85 * 85 +
          85 * 85 +
          85;
      out.write((r >> 24) & 0xFF);
    } else if (state == 3) {
      int r = chn[0] * 85 * 85 * 85 * 85 +
          chn[1] * 85 * 85 * 85 +
          chn[2] * 85 * 85 +
          85 * 85 +
          85;
      out.write((r >> 24) & 0xFF);
      out.write((r >> 16) & 0xFF);
    } else if (state == 4) {
      int r = chn[0] * 85 * 85 * 85 * 85 +
          chn[1] * 85 * 85 * 85 +
          chn[2] * 85 * 85 +
          chn[3] * 85 +
          85;
      out.write((r >> 24) & 0xFF);
      out.write((r >> 16) & 0xFF);
      out.write((r >> 8) & 0xFF);
    }
    return out.getBytes();
  }
}
