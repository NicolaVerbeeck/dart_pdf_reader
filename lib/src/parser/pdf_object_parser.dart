import 'package:dart_pdf_reader/src/model/pdf_types.dart';
import 'package:dart_pdf_reader/src/parser/indirect_object_parser.dart';
import 'package:dart_pdf_reader/src/parser/token_stream.dart';
import 'package:dart_pdf_reader/src/utils/random_access_stream.dart';
import 'package:dart_pdf_reader/src/utils/reader_helper.dart';

class PDFObjectParser {
  final RandomAccessStream _buffer;
  final TokenStream _tokenStream;
  final IndirectObjectParser _indirectObjectParser;

  PDFObjectParser(
    this._buffer,
    this._indirectObjectParser,
  ) : _tokenStream = TokenStream(_buffer);

  Future<PDFObject> parse() async {
    final token = await _nextNonWhiteSpace();

    if (token == 0x3C) {
      // <
      if (await _tokenStream.nextToken() == 0x3C) {
        await _tokenStream.consumeToken();
        final dict = await _parseDictionary();
        final pos = await _buffer.position;
        if (await _nextNonWhiteSpace() == 0x73) {
          // s
          final stream = await _parseStream(dict);
          if (stream != null) {
            return stream;
          }
        }
        await _buffer.seek(pos);
        return dict;
      } else {
        return _parseHexString();
      }
    } else if (token == 0x28) {
      // (
      return _parseString();
    } else if (token == 0x74 ||
        (token == 0x66 && (await _tokenStream.nextToken()) == 0x61)) {
      // t, f, a
      return _parseBoolean(token);
    } else if (token == 0x2F) {
      // /
      return _parseName();
    } else if (token == 0x6E && ((await _tokenStream.nextToken()) == 0x75)) {
      // n u
      return _parseNull();
    } else if (token == 0x5B) {
      // [
      return _parseArray();
    } else if (_isNumeric(token)) {
      return _parseNumberOrObjectRef(token);
    } else if (token == 0x2B || token == 0x2D || token == 0x2E) {
      // + - .
      return _parseNumber(token);
    } else {
      return _parseCommand(token);
    }
  }

  Future<CharCode> _nextNonWhiteSpace() async {
    await ReaderHelper.skipUntilFirstNonWhitespace(_tokenStream);
    return _tokenStream.consumeToken();
  }

  Future<PDFNull> _parseNull() async {
    await _tokenStream.consumeToken(); // Consume u
    await _tokenStream.consumeToken(); // Consume l
    await _tokenStream.consumeToken(); // Consume l

    if (await _tokenStream.nextTokenType() == TokenType.normal) {
      throw Exception('Null was not followed by a delim or whitespace');
    }
    return const PDFNull();
  }

  Future<PDFObject> _parseNumberOrObjectRef(CharCode token) async {
    final position = await _buffer.position;
    final object = await _asObjectRef(token);
    if (object != null) {
      return object;
    }
    await _buffer.seek(position);
    return _parseNumber(token);
  }

  Future<PDFObject> _parseNumber(CharCode token) async {
    final chars = StringBuffer();
    chars.writeCharCode(token);
    while (await _tokenStream.nextTokenType() == TokenType.normal) {
      chars.writeCharCode(await _tokenStream.consumeToken());
    }
    return PDFNumber(num.parse(chars.toString()));
  }

  Future<PDFObjectReference?> _asObjectRef(CharCode token) async {
    final objectId = StringBuffer();
    final generationNumber = StringBuffer();

    objectId.writeCharCode(token);
    TokenType lastTokenType;
    while ((lastTokenType = await _tokenStream.nextTokenType()) ==
        TokenType.normal) {
      final token = await _tokenStream.consumeToken();
      if (!_isNumeric(token)) {
        return null;
      }
      objectId.writeCharCode(token);
    }
    if ((lastTokenType != TokenType.whitespace) &&
        (lastTokenType != TokenType.comment)) {
      return null;
    }

    token = await _nextNonWhiteSpace();
    if (!_isNumeric(token)) {
      return null;
    }
    generationNumber.writeCharCode(token);
    while ((lastTokenType = await _tokenStream.nextTokenType()) ==
        TokenType.normal) {
      token = await _tokenStream.consumeToken();
      if (!_isNumeric(token)) {
        return null;
      }
      generationNumber.writeCharCode(token);
    }
    if ((lastTokenType != TokenType.whitespace) &&
        (lastTokenType != TokenType.comment)) {
      return null;
    }

    token = await _nextNonWhiteSpace();
    if (token != 0x52) {
      // R
      return null;
    }
    if (await _tokenStream.nextTokenType() == TokenType.normal) {
      return null;
    }

    return PDFObjectReference(
      objectId: int.parse(objectId.toString()),
      generationNumber: int.parse(generationNumber.toString()),
    );
  }

  Future<PDFArray> _parseArray() async {
    final array = <PDFObject>[];

    TokenType type;
    while (true) {
      type = await _tokenStream.nextTokenType();
      if (type == TokenType.whitespace) {
        await _tokenStream.consumeToken();
        continue;
      } else if (type == TokenType.comment) {
        await ReaderHelper.readLine(_buffer);
        continue;
      } else if (type == TokenType.eof) {
        throw Exception('Unexpected end of file');
      }
      final token = await _tokenStream.nextToken();
      if (token == 0x5D) {
        // ]
        await _tokenStream.consumeToken();
        break;
      }
      array.add(await parse());
    }
    return PDFArray(array);
  }

  Future<PDFBoolean> _parseBoolean(CharCode token) async {
    while ((await _tokenStream.nextTokenType()) == TokenType.normal) {
      await _tokenStream.consumeToken();
    }
    return PDFBoolean(token == 0x74); // 't'
  }

  Future<PDFName> _parseName() async {
    final name = StringBuffer();
    while ((await _tokenStream.nextTokenType()) == TokenType.normal) {
      name.writeCharCode(await _tokenStream.consumeToken());
    }
    return PDFName(name.toString());
  }

  Future<PDFHexString> _parseHexString() async {
    final hexString = StringBuffer();
    while ((await _tokenStream.nextToken()) != 0x3E) {
      // >
      final type = await _tokenStream.nextTokenType();
      if (type == TokenType.whitespace) {
        await _tokenStream.consumeToken();
        continue;
      } else if (type == TokenType.comment) {
        await ReaderHelper.readLine(_buffer);
        continue;
      } else if (type == TokenType.eof) {
        throw Exception('Unexpected end of file');
      }
      hexString.writeCharCode(await _tokenStream.consumeToken());
    }
    if ((hexString.length % 2) == 1) {
      hexString.writeCharCode(0x30);
    }

    return PDFHexString(ReaderHelper.fromHex(hexString.toString()));
  }

  Future<PDFObject> _parseCommand(CharCode token) async {
    final command = StringBuffer();
    command.writeCharCode(token);
    while ((await _tokenStream.nextTokenType()) == TokenType.normal &&
        _isValidCommandCharacter(await _tokenStream.nextToken())) {
      command.writeCharCode(await _tokenStream.consumeToken());
    }
    return PDFCommand(command.toString());
  }

  Future<PDFDictionary> _parseDictionary() async {
    final entries = <PDFName, PDFObject>{};
    CharCode token;
    while ((token = await _nextNonWhiteSpace()) != 0x3E) {
      assert(token == 0x2F); // /
      final name = await _parseName();

      entries[name] = await parse();
    }
    token = await _tokenStream.consumeToken();
    assert(token == 0x3E);
    return PDFDictionary(entries);
  }

  Future<PDFStreamObject?> _parseStream(PDFDictionary dictionary) async {
    final line = await ReaderHelper.readLine(_buffer);
    if ('tartxref' == line) return null;
    assert('tream' == line);

    var object = dictionary[const PDFName('Length')];
    while (object is PDFObjectReference) {
      object = await _indirectObjectParser.getObjectFor(object);
    }
    if (object is! PDFNumber) {
      throw Exception('Length is not a number');
    }
    final length = object.toInt();
    final start = await _buffer.position;
    await _buffer.seek(start + length);
    final endLine = await ReaderHelper.readLineSkipEmpty(_buffer);
    assert(endLine == 'endstream');

    return PDFStreamObject(
      dictionary: dictionary,
      dataSource: _buffer,
      offset: start,
      length: length,
      isBinary: dictionary.has(const PDFName('Filter')),
    );
  }

  Future<PDFLiteralString> _parseString() async {
    final builder = <int>[];
    var numBracketsLeft = 1;
    var escaping = false;
    while (true) {
      final token = await _tokenStream.consumeToken();
      if (escaping) {
        if (token == 0x6E) {
          // n
          builder.add(0x0A);
        } else if (token == 0x72) {
          // r
          builder.add(0x0D);
        } else if (token == 0x74) {
          // t
          builder.add(0x09);
        } else if (token == 0x66) {
          // f
          builder.add(0x0C);
        } else if (token == 0x28) {
          // (
          builder.add(0x28);
        } else if (token == 0x29) {
          // )
          builder.add(0x29);
        } else if (token == 0x5C) {
          // \
          builder.add(0x5C);
        } else if (_isOctal(token)) {
          builder.add(await _parseOctal(token));
        } else if (token == 0x0D && (await _tokenStream.nextToken()) == 0x0A) {
          // \r\n
          await _tokenStream.consumeToken();
        }
        escaping = false;
        continue;
      }
      if (token == 0x5C) {
        // \
        escaping = true;
        continue;
      } else if (token == 0x28) {
        // (
        ++numBracketsLeft;
        builder.add(token);
      } else if (token == 0x29) {
        // )
        --numBracketsLeft;
        if (numBracketsLeft == 0) {
          break;
        }
        builder.add(token);
      } else {
        builder.add(token);
      }
    }
    return PDFLiteralString(builder);
  }

  Future<CharCode> _parseOctal(CharCode firstDigit) async {
    final builder = StringBuffer();
    builder.writeCharCode(firstDigit);
    for (var i = 0; i < 2; i++) {
      final token = await _tokenStream.nextToken();
      if (!_isOctal(token)) {
        break;
      }
      builder.writeCharCode(await _tokenStream.consumeToken());
    }
    return int.parse(builder.toString(), radix: 8);
  }
}

bool _isNumeric(CharCode token) {
  return token >= 0x30 && token <= 0x39; // 0-9
}

bool _isValidCommandCharacter(final CharCode c) {
  return !((c == 0x2D) || (c == 0x2B) || (c == 0x2E)) && !_isNumeric(c);
}

bool _isOctal(CharCode token) {
  return token >= 0x30 && token <= 0x37; // 0-7
}
