import 'package:dart_pdf_reader/dart_pdf_reader.dart';
import 'package:dart_pdf_reader/src/parser/token_stream.dart';

class ReaderHelper {
  ReaderHelper._();

  static Future<String?> readLineSkipEmpty(RandomAccessStream buffer) async {
    String? line;
    while ((line = await readLine(buffer)) != null) {
      line = removeComments(line!).trim();
      if (line.isNotEmpty) {
        return line;
      }
    }
    return null;
  }

  static Future<String?> readLine(RandomAccessStream buffer) async {
    final builder = StringBuffer();

    CharCode ch;
    var read = false;

    while ((ch = await buffer.readByte()) != -1) {
      read = true;
      if (ch == 13) {
        final next = await buffer.peekByte();
        //Skip next
        if (next == 10) {
          await buffer.readByte();
        }
        break;
      } else if (ch == 10) {
        break;
      } else {
        builder.writeCharCode(ch);
      }
    }

    if (!read) {
      return null;
    }

    return builder.toString();
  }

  static List<int> fromHex(String string) {
    final len = string.length;
    final out = List<int>.filled(len ~/ 2, 0);

    for (int i = 0; i < len; i += 2) {
      int h = hexToBin(string.codeUnitAt(i));
      int l = hexToBin(string.codeUnitAt(i + 1));
      if (h == -1 || l == -1) {
        throw ArgumentError(
            "contains illegal character for hexBinary: $string");
      }
      out[i ~/ 2] = (h * 16 + l);
    }

    return out;
  }

  static int hexToBin(CharCode ch) {
    if (0x30 <= ch && ch <= 0x39) {
      return ch - 0x30;
    }
    if (0x41 <= ch && ch <= 0x46) {
      return ch - 0x41 + 10;
    }
    if (0x61 <= ch && ch <= 0x66) {
      return ch - 0x61 + 10;
    }
    return -1;
  }

  static String removeComments(String line) {
    if (line.startsWith('%')) {
      if (line.toLowerCase() == '%%eof' ||
          RegExp('%PDF-\\d.\\d').hasMatch(line)) {
        return line;
      }
    }
    final index = line.indexOf('%');
    if (index == -1) {
      return line;
    }
    return line.substring(0, index);
  }

  static Future<void> skipUntilFirst(RandomAccessStream buffer, int i) async {
    while (true) {
      final ch = await buffer.readByte();
      if (ch == -1) {
        throw Exception('EOF');
      }
      if (ch == i) {
        await buffer.seek(await buffer.position - 1); // Go back a single one
        return;
      } else if (ch == 0x25) {
        // % -> skip until eol
        await readLineSkipEmpty(buffer);
      }
    }
  }

  static Future<void> readObjectHeader(TokenStream tokenStream) async {
    await skipUntilFirstNonWhitespace(
        tokenStream); // Consume all whitespace before
    await skipUntilWhiteSpace(tokenStream); // object id
    await skipUntilFirstNonWhitespace(tokenStream);
    await skipUntilWhiteSpace(tokenStream); // generation number
    await skipUntilFirstNonWhitespace(tokenStream);
    await skipUntilWhiteSpace(tokenStream); // obj
    await skipUntilFirstNonWhitespace(tokenStream); // Remaining whitespace
  }

  static Future<void> skipUntilFirstNonWhitespace(
    TokenStream tokenStream,
  ) async {
    while (await tokenStream.nextTokenType() == TokenType.whitespace) {
      await tokenStream.consumeToken();
    }
    if (await tokenStream.nextTokenType() == TokenType.comment) {
      await readLine(tokenStream.buffer);
      return skipUntilFirstNonWhitespace(tokenStream);
    }
    if (await tokenStream.nextTokenType() == TokenType.eof) {
      throw Exception('Unexpected end of file');
    }
  }

  static Future<void> skipUntilWhiteSpace(TokenStream tokenStream) async {
    do {
      final type = await tokenStream.nextTokenType();
      if (type == TokenType.whitespace) return;
      if (type == TokenType.eof) throw Exception('Unexpected end of file');
      await tokenStream.consumeToken();
    } while (true);
  }
}
