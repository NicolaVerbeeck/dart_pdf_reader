import 'dart:typed_data';

class ByteInputStream {
  final Uint8List _bytes;
  var _position = 0;

  ByteInputStream(this._bytes);

  int readByte() {
    if (_position >= _bytes.length) {
      throw Exception('End of stream');
    }
    return _bytes[_position++];
  }

  void readFully(List<int> current, int offset, int length) {
    if (_position + length > _bytes.length) {
      throw Exception('End of stream');
    }
    for (var i = 0; i < length; i++) {
      current[offset + i] = _bytes[_position++];
    }
  }

  int readBytesToInt(int width) {
    var result = 0;
    for (var i = 0; i < width; i++) {
      result = (result << 8) | (readByte() & 0xFF);
    }
    return result;
  }
}

class ByteOutputStream {
  static const _growSize = 1024;

  Uint8List _bytes;
  var _position = 0;

  ByteOutputStream(int capacity) : _bytes = Uint8List(capacity);

  Uint8List getBytes() {
    if (_position == _bytes.length) {
      return _bytes;
    }
    return Uint8List.view(_bytes.buffer, 0, _position);
  }

  void write(int byte) {
    if (_position >= _bytes.length) {
      _bytes = Uint8List(_bytes.length + _growSize)..setAll(0, _bytes);
    }
    _bytes[_position++] = byte;
  }

  void writeAll(Uint8List current) {
    if (_position + current.length > _bytes.length) {
      _bytes = Uint8List(_bytes.length + current.length + _growSize)
        ..setAll(0, _bytes);
    }
    _bytes.setAll(_position, current);
    _position += current.length;
  }
}
