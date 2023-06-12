import 'package:dart_pdf_reader/src/utils/random_access_stream.dart';

typedef CharCode = int;

class TokenStream {
  final RandomAccessStream buffer;

  const TokenStream(this.buffer);

  Future<CharCode> consumeToken() => buffer.readByte();

  Future<CharCode> nextToken() => _readToken();

  Future<TokenType> nextTokenType() async =>
      _determineTokenType(await _readToken());

  Future<CharCode> _readToken() => buffer.peekByte();

  TokenType _determineTokenType(CharCode token) {
    if (_isDelim(token)) {
      return TokenType.delimiter;
    } else if (_isWhitespace(token)) {
      return TokenType.whitespace;
    } else if (token == 0x25) {
      return TokenType.comment;
    } else if (token == -1) {
      return TokenType.eof;
    } else {
      return TokenType.normal;
    }
  }
}

bool _isDelim(CharCode token) {
  return token == 0x28 || // (
      token == 0x29 || // )
      token == 0x3C || // <
      token == 0x3E || // >
      token == 0x5B || // [
      token == 0x5D || // ]
      token == 0x7B || // {
      token == 0x7D || // }
      token == 0x2F; // /
}

bool _isWhitespace(CharCode token) {
  return token == 0x00 || // null
      token == 0x09 || // tab
      token == 0x0A || // line feed
      token == 0x0C || // form feed
      token == 0x0D || // carriage return
      token == 0x20; // space
}

enum TokenType {
  eof,
  delimiter,
  whitespace,
  comment,
  normal,
}
