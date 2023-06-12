import 'dart:math';

import 'package:dart_pdf_reader/src/utils/random_access_stream.dart';

/// Implementation of [RandomAccessStream] which reads from a list of bytes
class ByteStream extends RandomAccessStream {
  final List<int> _bytes;
  var _position = 0;

  @override
  late final Future<int> length = Future.value(_bytes.length);

  @override
  Future<int> get position => Future.value(_position);

  /// Create a new [ByteStream] from a list of bytes
  ByteStream(this._bytes);

  @override
  Future<int> peekByte() {
    if (_position == _bytes.length) return Future.value(-1);
    return Future.value(_bytes[_position]);
  }

  @override
  Future<int> readBuffer(int count, List<int> into) {
    var i = 0;
    final end = min(count, _bytes.length - _position);
    for (; i < end; ++i) {
      into[i] = _bytes[_position++];
    }
    return Future.value(i);
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
