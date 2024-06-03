import 'dart:io';
import 'dart:typed_data';

import 'random_access_stream.dart';

/// Implementation of [RandomAccessStream] which reads from a file
/// Currently this does not perform smart buffering and can be quite slow
///
/// Wrap a [FileStream] in a [BufferedRandomAccessStream] to improve performance
class FileStream extends RandomAccessStream {
  final RandomAccessFile _file;

  @override
  late final Future<int> length = _file.length();

  @override
  Future<int> get position => _file.position();

  /// Create a new [FileStream] from a file
  FileStream(this._file);

  @override
  Future<int> readBuffer(int count, Uint8List into) {
    return _file.readInto(into, 0, count);
  }

  @override
  Future<int> readByte() {
    return _file.readByte();
  }

  @override
  Future<int> peekByte() async {
    final current = await position;
    if (current == await length) {
      return -1;
    }

    final byte = await readByte();
    await seek(current);
    return byte;
  }

  @override
  Future<void> seek(int offset) {
    return _file.setPosition(offset);
  }
}
