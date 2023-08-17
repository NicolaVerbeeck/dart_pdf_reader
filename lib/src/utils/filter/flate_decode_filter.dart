part of 'stream_filter.dart';

class FlateDecodeFilter extends StreamFilter {
  const FlateDecodeFilter._() : super._();

  @override
  Uint8List decode(
    Uint8List bytes,
    PDFObject? params,
    PDFDictionary streamDictionary,
  ) {
    final decoded = zlib.decode(bytes).asUint8List();
    if (params is PDFDictionary) return _decodeWithPredictor(decoded, params);
    return decoded;
  }

  // From iTextPDF 7
  static Uint8List _decodeWithPredictor(Uint8List bytes, PDFDictionary params) {
    final predictor = params[const PDFName('Predictor')];
    if (predictor is! PDFNumber) return bytes;

    final predictorInt = predictor.toInt();
    if (predictorInt < 10 && predictorInt != 2) return bytes;

    final width = params[const PDFName('Columns')]?.toIntOrNull() ?? 1;
    final colors = params[const PDFName('Colors')]?.toIntOrNull() ?? 1;
    final bitsPerComponent =
        params[const PDFName('BitsPerComponent')]?.toIntOrNull() ?? 8;
    final bytesPerPixel = (colors * bitsPerComponent) ~/ 8;
    final bytesPerRow = (colors * width * bitsPerComponent + 7) ~/ 8;

    if (predictorInt == 2) {
      if (bitsPerComponent == 8) {
        final numRows = bytes.length ~/ bytesPerRow;
        for (int row = 0; row < numRows; row++) {
          int rowStart = row * bytesPerRow;
          for (int col = bytesPerPixel; col < bytesPerRow; col++) {
            bytes[rowStart + col] = (bytes[rowStart + col] +
                    bytes[rowStart + col - bytesPerPixel]) &
                0xFF;
          }
        }
      }
      return bytes;
    }

    var current = Uint8List(bytesPerRow);
    var prior = Uint8List(bytesPerRow);
    final dataStream = ByteInputStream(bytes);
    final fout = ByteOutputStream(bytes.length);

    while (true) {
      final int filter;
      try {
        filter = dataStream.readByte();
        if (filter < 0) return fout.getBytes();
        dataStream.readFully(current, 0, bytesPerRow);
      } catch (ignored) {
        return fout.getBytes();
      }

      switch (filter) {
        case 0: // PNG_FILTER_NONE
          break;
        case 1: //PNG_FILTER_SUB
          for (int i = bytesPerPixel; i < bytesPerRow; i++) {
            current[i] += current[i - bytesPerPixel];
          }
          break;
        case 2: //PNG_FILTER_UP
          for (int i = 0; i < bytesPerRow; i++) {
            current[i] += prior[i];
          }
          break;
        case 3: //PNG_FILTER_AVERAGE
          for (int i = 0; i < bytesPerPixel; i++) {
            current[i] += (prior[i] ~/ 2) & 0xFF;
          }
          for (int i = bytesPerPixel; i < bytesPerRow; i++) {
            current[i] +=
                (((current[i - bytesPerPixel] & 0xff) + (prior[i] & 0xff)) ~/
                        2) &
                    0xFF;
          }
          break;
        case 4: //PNG_FILTER_PAETH
          for (int i = 0; i < bytesPerPixel; i++) {
            current[i] += prior[i];
          }

          for (int i = bytesPerPixel; i < bytesPerRow; i++) {
            int a = current[i - bytesPerPixel] & 0xff;
            int b = prior[i] & 0xff;
            int c = prior[i - bytesPerPixel] & 0xff;

            int p = a + b - c;
            int pa = (p - a).abs();
            int pb = (p - b).abs();
            int pc = (p - c).abs();

            int ret;

            if (pa <= pb && pa <= pc) {
              ret = a;
            } else if (pb <= pc) {
              ret = b;
            } else {
              ret = c;
            }
            current[i] += ret & 0xFF;
          }
          break;
        default:
          throw const ParseException('Unknown png filter');
      }
      fout.writeAll(current);
      final tmp = prior;
      prior = current;
      current = tmp;
    }
  }
}

extension _ObjectExtension on PDFObject {
  int? toIntOrNull() {
    if (this is PDFNumber) return (this as PDFNumber).toInt();
    return null;
  }
}
