import 'package:dart_pdf_reader/src/error/exceptions.dart';

/// An abstraction of a stream of bytes that can be read from.
abstract class RandomAccessStream {
  /// Attempts to read a single byte from the stream. Reading past the end of
  /// the stream will return -1.
  Future<int> readByte();

  /// Attempts to read [count] bytes from the stream into [into]. Returns the
  /// number of bytes read (which can be < [count] if the end of the stream
  /// has been reached).
  Future<int> readBuffer(int count, List<int> into);

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
      var c = await readByte();
      if (c == -1) {
        if (line.length == 0) {
          throw EOFException();
        } else {
          return line.toString();
        }
      } else if (c == 0x0A) {
        return line.toString();
      } else if (c != 0x0D) {
        line.writeCharCode(c);
      }
    }
  }
}
