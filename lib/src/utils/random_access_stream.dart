import 'dart:typed_data';

import '../error/exceptions.dart';

/// An abstraction of a stream of bytes that can be read from.
abstract class RandomAccessStream {
  /// Attempts to read a single byte from the stream. Reading past the end of
  /// the stream will return -1.
  Future<int> readByte();

  /// Attempts to read [count] bytes from the stream into [into]. Returns the
  /// number of bytes read (which can be < [count] if the end of the stream
  /// has been reached).
  Future<int> readBuffer(int count, Uint8List into);

  /// A potentially faster variant of [readBuffer].
  ///
  /// Subclasses are free to implement this in any way that is faster than
  /// calling [readBuffer]
  Future<Uint8List> fastRead(int count) async {
    final list = Uint8List(count);
    final actual = await readBuffer(count, list);
    return Uint8List.view(list.buffer, 0, actual);
  }

  /// Seeks to the given [offset] in the stream (from the beginning).
  Future<void> seek(int offset);

  /// Returns the next byte in the stream without advancing the position.
  /// Returns -1 if the end of the stream has been reached.
  Future<int> peekByte();

  /// Returns the length of the stream in bytes.
  Future<int> get length;

  /// Returns the current position in the stream.
  Future<int> get position;

  /// Reads a single line from the stream. A line is terminated by 0x0A (possibly preceded by 0x0D).
  /// The line terminator is not included in the returned string.
  /// Throws an [EOFException] if the end of the stream is reached before a line terminator is found AND no characters have been read.
  Future<String> readLine() async {
    final line = StringBuffer();
    while (true) {
      final c = await readByte();
      if (c == -1) {
        if (line.length == 0) {
          throw const EOFException();
        } else {
          return line.toString();
        }
      } else if (c == 0x0A) {
        return line.toString();
      } else if (c != 0x0D) {
        line.writeCharCode(c);
      } else if (c == 0x0D) {
        final next = await peekByte();
        if (next == 0x0A) {
          await readByte();
        }
        return line.toString();
      }
    }
  }
}
