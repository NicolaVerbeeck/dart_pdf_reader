part of 'stream_filter.dart';

class LZWDecodeFilter extends StreamFilter {
  const LZWDecodeFilter._() : super._();

  @override
  Uint8List decode(
    Uint8List bytes,
    PDFObject? params,
    PDFDictionary streamDictionary,
  ) {
    final decompressed = _lzwDecompress(bytes);
    if (params is PDFDictionary) {
      return FlateDecodeFilter._decodeWithPredictor(decompressed, params);
    }
    return decompressed;
  }

  Uint8List _lzwDecompress(List<int> compressedData) {
    final output = ByteOutputStream(compressedData.length);
    _LZWDecoder(compressedData, output).decode();
    return output.getBytes();
  }
}

// Adapted from itext7 sources
class _LZWDecoder {
  final ByteOutputStream _output;
  final List<int> _data;
  var _nextBits = 0;
  var _nextData = 0;
  var _bytePointer = 0;
  var _bitsToGet = 9;
  var _tableIndex = 0;
  late List<List<int>> _stringTable;

  static const _andTable = [511, 1023, 2047, 4095];

  _LZWDecoder(this._data, this._output);

  void decode() {
    if (_data.length < 2) {
      throw ParseException('Bad LZW encoded length');
    }
    if (_data[0] == 0x00 && _data[1] == 0x01) {
      throw ParseException('LZW flavour not supported');
    }
    _initializeStringTable();
    _nextBits = 0;
    _nextData = 0;
    _bytePointer = 0;

    var code = 0;
    var oldCode = 0;
    List<int>? string;
    while ((code = _getNextCode()) != 257) {
      if (code == 256) {
        _initializeStringTable();
        code = _getNextCode();
        if (code == 257) {
          break;
        }
        _writeString(_stringTable[code]);
        oldCode = code;
      } else {
        if (code < _tableIndex) {
          string = _stringTable[code];
          _writeString(string);
          _copyStringToTable(_stringTable[oldCode] + <int>[string[0]]);
          oldCode = code;
        } else {
          string = _stringTable[oldCode] + <int>[_stringTable[oldCode][0]];
          _writeString(string);
          _copyStringToTable(string);
          oldCode = code;
        }
      }
    }
  }

  void _initializeStringTable() {
    _stringTable = List.generate(4096, (i) => i < 256 ? <int>[i] : []);
    _tableIndex = 258;
    _bitsToGet = 9;
  }

  void _writeString(List<int> string) {
    _output.writeAll(string);
  }

  void _copyStringToTable(List<int> string) {
    _addStringToTable(<int>[...string]);
  }

  void _addStringToTable(List<int> string) {
    _stringTable[_tableIndex++] = string;
    if (_tableIndex == 511) {
      _bitsToGet = 10;
    } else if (_tableIndex == 1023) {
      _bitsToGet = 11;
    } else if (_tableIndex == 2047) {
      _bitsToGet = 12;
    }
  }

  int _getNextCode() {
    try {
      _nextData = (_nextData << 8) | (_getDataOrThrow(_bytePointer++) & 0xff);
      _nextBits += 8;
      if (_nextBits < _bitsToGet) {
        _nextData = (_nextData << 8) | (_getDataOrThrow(_bytePointer++) & 0xff);
        _nextBits += 8;
      }
      final code =
          (_nextData >> (_nextBits - _bitsToGet)) & _andTable[_bitsToGet - 9];
      _nextBits -= _bitsToGet;

      return code;
    } on _OOBException {
      return 257;
    }
  }

  int _getDataOrThrow(int position) {
    if (position < _data.length) {
      return _data[position];
    } else {
      throw _OOBException();
    }
  }
}

class _OOBException implements Exception {}
