import 'package:dart_pdf_reader/dart_pdf_reader.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('ByteStream tests', () {
    test('Test single read', () async {
      final stream = ByteStream([1, 2, 3]);
      expect(await stream.readByte(), 1);
      expect(await stream.readByte(), 2);
      expect(await stream.readByte(), 3);
    });
    test('Test single read outside range', () async {
      final stream = ByteStream([1]);
      expect(await stream.readByte(), 1);
      expect(await stream.readByte(), -1);
    });
    test('Test seek inside', () async {
      final stream = ByteStream([1, 2, 3]);
      await stream.seek(1);
      expect(await stream.readByte(), 2);
      expect(await stream.readByte(), 3);
      expect(await stream.readByte(), -1);
    });
    test('Test seek sets position read', () async {
      final stream = ByteStream([1, 2, 3]);
      expect(await stream.position, 0);
      await stream.seek(2);
      expect(await stream.position, 2);
    });
    test('Read advances position', () async {
      final stream = ByteStream([1, 2, 3]);
      expect(await stream.position, 0);
      await stream.readByte();
      expect(await stream.position, 1);
    });
    test('Test length', () async {
      final stream = ByteStream([1, 2, 3]);
      expect(await stream.length, 3);
    });
    test('Test peekByte', () async {
      final stream = ByteStream([1, 2, 3]);
      expect(await stream.peekByte(), 1);
      expect(await stream.position, 0);
      await stream.seek(3);
      expect(await stream.peekByte(), -1);
    });
    test('Test read buffer', () async {
      final stream = ByteStream([1, 2, 3]);
      final buffer = List<int>.filled(2, 0);
      expect(await stream.readBuffer(2, buffer), 2);
      expect(buffer, [1, 2]);
      expect(await stream.readByte(), 3);
    });
    test('Test read buffer overflow', () async {
      final stream = ByteStream([1, 2, 3]);
      final buffer = List<int>.filled(4, 0);
      expect(await stream.readBuffer(4, buffer), 3);
      expect(buffer, [1, 2, 3, 0]);
      expect(await stream.readByte(), -1);
    });
  });
}
