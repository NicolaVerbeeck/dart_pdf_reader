import 'dart:typed_data';

import 'package:dart_pdf_reader/dart_pdf_reader.dart';
import 'package:dart_pdf_reader/src/parser/token_stream.dart';

abstract class ReaderHelper {

  /// Try to read the first non-empty line from the buffer, stripping comments
  /// and skipping empty lines. Returns null if end of stream was reached.
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

  /// Attempts to read a line from the buffer, returning null if end of stream
  /// was reached. See [RandomAccessStream.readLine].
  static Future<String?> readLine(RandomAccessStream buffer) async {
    try {
      return await buffer.readLine();
    } on EOFException {
      return null;
    }
  }

  /// Parses the hex string (without surrounding <>) into a list of bytes.
  static Uint8List fromHex(String string) {
    final len = string.length;
    final out = Uint8List(len ~/ 2);

    for (int i = 0; i < len; i += 2) {
      int h = _hexToBin(string.codeUnitAt(i));
      int l = _hexToBin(string.codeUnitAt(i + 1));
      if (h == -1 || l == -1) {
        throw ArgumentError(
            "contains illegal character for hexBinary: $string");
      }
      out[i ~/ 2] = (h * 16 + l);
    }

    return out;
  }

  /// Strip all comments from the given line. Unless the line is '%%EOF' or the
  /// pdf version start line (%PDF-\d.\d), in which case the lines are
  /// returned as is
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

  /// Skip all bytes until the first one matching [i] is found. If [i] is not
  /// found, an [EOFException] is thrown. The [buffer] is positioned at the
  /// [i] byte when this method returns successfully.
  /// Comments are skipped when searching for the relevant byte
  static Future<void> skipUntilFirst(RandomAccessStream buffer, int i) async {
    while (true) {
      final ch = await buffer.readByte();
      if (ch == -1) {
        throw EOFException();
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

  /// Skips past the object header (\d \d obj) on the token stream
  /// Throws if no object header is found
  /// Throws if no object data is present after the header
  static Future<void> skipObjectHeader(TokenStream tokenStream) async {
    await skipUntilFirst(tokenStream.buffer, 0x6A); //j
    await tokenStream.consumeToken(); // Consume j
    await skipUntilFirstNonWhitespace(tokenStream); // Remaining whitespace
  }

  /// Skips tokens in the stream until the first non-whitespace token is found
  /// If a comment is found, the entire line is skipped
  /// Throws if end of file is reached
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
      throw EOFException();
    }
  }

  static int _hexToBin(CharCode ch) {
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

  static Future<int> readNumber(TokenStream tokenStream) async {
    await skipUntilFirstNonWhitespace(tokenStream);

    final numberString = StringBuffer();
    while (true) {
      final tokenType = await tokenStream.nextTokenType();
      if (tokenType != TokenType.normal) break;
      numberString.writeCharCode(await tokenStream.consumeToken());
    }
    if (numberString.isEmpty) {
      throw ParseException('Expected number, not nothing');
    }
    return int.parse(numberString.toString());
  }
}
