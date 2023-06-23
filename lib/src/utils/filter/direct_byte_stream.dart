class ByteInputStream {
  final List<int> _bytes;
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
  final List<int> _bytes;
  var _position = 0;

  ByteOutputStream(int capacity) : _bytes = <int>[];

  List<int> getBytes() {
    if (_position == _bytes.length) {
      return _bytes;
    }
    return _bytes.sublist(0, _position);
  }

  void write(int byte) {
    _bytes.add(byte);
    ++_position;
  }

  void writeAll(List<int> current) {
    for (var i = 0; i < current.length; i++) {
      _bytes.add(current[i]);
      ++_position;
    }
  }
}
