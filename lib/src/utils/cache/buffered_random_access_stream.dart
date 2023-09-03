import 'dart:math';
import 'dart:typed_data';

import 'package:dart_pdf_reader/src/utils/byte_stream.dart';
import 'package:dart_pdf_reader/src/utils/cache/lru_map.dart';
import 'package:dart_pdf_reader/src/utils/random_access_stream.dart';

/// Implementation of [RandomAccessStream] which buffers reads from another stream
/// This is useful for improving performance when reading from a slow stream
class BufferedRandomAccessStream extends RandomAccessStream {
  final RandomAccessStream _stream;
  final LRUMap<int, Uint8List> _cache;
  final int _blockSize;
  var _position = 0;

  @override
  Future<int> get length => _stream.length;

  @override
  Future<int> get position => Future.value(_position);

  /// Create a new [BufferedRandomAccessStream] from another [RandomAccessStream]
  /// Using this class with a full [ByteStream] is not recommended
  ///
  /// [blockSize] is the size of each block to read from the stream
  /// [maxNumBlocks] is the maximum number of blocks to keep in memory cache
  BufferedRandomAccessStream(
    this._stream, {
    int blockSize = 1024 * 1024,
    int maxNumBlocks = 10,
  })  : _blockSize = blockSize,
        _cache = LRUMap(maxNumBlocks) {
    if (_stream is ByteStream) {
      print(
        'Warning: BufferedRandomAccessStream is not recommended for ByteStream',
      );
    }
  }

  @override
  Future<int> peekByte() async {
    if (_position == await length) return Future.value(-1);
    final (buffer, index) = await _getSingleBlock(_position);
    return buffer[index];
  }

  @override
  Future<int> readBuffer(int count, Uint8List into) async {
    final actualCount = min(count, (await length) - _position);
    var read = 0;
    while (read < actualCount) {
      final (buffer, index) = await _getSingleBlock(_position);
      final remaining = min(actualCount - read, _blockSize - index);
      into.setRange(read, read + remaining, buffer, index);
      read += remaining;
      _position += remaining;
    }
    return read;
  }

  @override
  Future<int> readByte() async {
    if (_position == await length) return Future.value(-1);
    final (buffer, index) = await _getSingleBlock(_position++);
    return buffer[index];
  }

  @override
  Future<void> seek(int offset) {
    _position = offset;
    return Future.value();
  }

  Future<(Uint8List, int)> _getSingleBlock(int index) async {
    final blockIndex = index ~/ _blockSize;
    var buffer = _cache[blockIndex];
    if (buffer == null) {
      await _stream.seek(blockIndex * _blockSize);
      buffer = await _stream.fastRead(_blockSize);
      _cache[blockIndex] = buffer;
    }
    return (buffer, index % _blockSize);
  }
}
