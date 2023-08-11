import 'dart:math';
import 'dart:typed_data';

import 'package:dart_pdf_reader/src/utils/random_access_stream.dart';

/// Implementation of [RandomAccessStream] which reads from a list of bytes
class ByteStream extends RandomAccessStream {
  final Uint8List _bytes;
  var _position = 0;
  final int _length;

  @override
  Future<int> get length => Future.value(_length);

  @override
  Future<int> get position => Future.value(_position);

  /// Create a new [ByteStream] from a list of bytes
  ByteStream(List<int> bytes)
      : _bytes = bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
        _length = bytes.length;

  @override
  Future<int> peekByte() {
    if (_position == _bytes.length) return Future.value(-1);
    return Future.value(_bytes[_position]);
  }

  @override
  Future<int> readBuffer(int count, Uint8List into) {
    var i = 0;
    final actualCount = min(count, _bytes.length - _position);
    for (; i < actualCount; ++i) {
      into[i] = _bytes[_position++];
    }
    return Future.value(i);
  }

  @override
  Future<Uint8List> fastRead(int count) async {
    final actualCount = min(count, _bytes.length - _position);
    final result = Uint8List.view(_bytes.buffer, _position, actualCount);
    _position += actualCount;
    return result;
  }

  @override
  Future<int> readByte() {
    if (_position == _bytes.length) return Future.value(-1);
    return Future.value(_bytes[_position++]);
  }

  @override
  Future<void> seek(int offset) {
    _position = offset;
    return Future.value();
  }
}
