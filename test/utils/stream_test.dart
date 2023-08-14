import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_pdf_reader/src/error/exceptions.dart';
import 'package:dart_pdf_reader/src/utils/byte_stream.dart';
import 'package:dart_pdf_reader/src/utils/random_access_stream.dart';
import 'package:test/test.dart';

void main() {
  group('Readline tests', () {
    test('Test read line normal', () async {
      final stream = ByteStream(Uint8List.fromList(utf8.encode('123\n456')));
      expect(await stream.readLine(), '123');
    });
    test('Test read carriage return', () async {
      final stream = ByteStream(Uint8List.fromList(utf8.encode('123\r\n456')));
      expect(await stream.readLine(), '123');
    });
    test('Test read line no newline', () async {
      final stream = ByteStream(Uint8List.fromList(utf8.encode('123')));
      expect(await stream.readLine(), '123');
    });
    test('Test read line empty', () async {
      final stream = ByteStream(Uint8List.fromList(utf8.encode('')));
      expect(stream.readLine(), throwsA(isA<EOFException>()));
    });
    test('Test read line, not empty but direct new line', () async {
      final stream = ByteStream(Uint8List.fromList(utf8.encode('\n\n')));
      expect(await stream.readLine(), '');
    });
    test('Test read line multiple', () async {
      final stream =
          ByteStream(Uint8List.fromList(utf8.encode('123\n456\n789')));
      expect(await stream.readLine(), '123');
      expect(await stream.readLine(), '456');
      expect(await stream.readLine(), '789');
    });
    test('Test read line multiple', () async {
      final stream =
          ByteStream(Uint8List.fromList(utf8.encode('123\r\n456\r789')));
      expect(await stream.readLine(), '123');
      expect(await stream.readLine(), '456');
      expect(await stream.readLine(), '789');
    });
  });
}

void createStreamTests(RandomAccessStream Function() streamProducer) {
  test('Test single read', () async {
    final stream = streamProducer();
    expect(await stream.readByte(), 1);
    expect(await stream.readByte(), 2);
    expect(await stream.readByte(), 3);
  });
  test('Test single read outside range', () async {
    final stream = streamProducer();

    expect(await stream.readByte(), 1);
    expect(await stream.readByte(), 2);
    expect(await stream.readByte(), 3);
    expect(await stream.readByte(), -1);
  });
  test('Test seek inside', () async {
    final stream = streamProducer();
    await stream.seek(1);
    expect(await stream.readByte(), 2);
    expect(await stream.readByte(), 3);
    expect(await stream.readByte(), -1);
  });
  test('Test seek sets position read', () async {
    final stream = streamProducer();
    expect(await stream.position, 0);
    await stream.seek(2);
    expect(await stream.position, 2);
  });
  test('Read advances position', () async {
    final stream = streamProducer();
    expect(await stream.position, 0);
    await stream.readByte();
    expect(await stream.position, 1);
  });
  test('Test length', () async {
    final stream = streamProducer();
    expect(await stream.length, 3);
  });
  test('Test peekByte', () async {
    final stream = streamProducer();
    expect(await stream.peekByte(), 1);
    expect(await stream.position, 0);
    await stream.seek(3);
    expect(await stream.peekByte(), -1);
  });
  test('Test read buffer', () async {
    final stream = streamProducer();
    final buffer = Uint8List(2);
    expect(await stream.readBuffer(2, buffer), 2);
    expect(buffer, [1, 2]);
    expect(await stream.readByte(), 3);
  });
  test('Test read buffer overflow', () async {
    final stream = streamProducer();
    final buffer = Uint8List(4);
    expect(await stream.readBuffer(4, buffer), 3);
    expect(buffer, [1, 2, 3, 0]);
    expect(await stream.readByte(), -1);
  });
  test('Test read buffer after end', () async {
    final stream = streamProducer();
    final buffer = Uint8List(4);
    await stream.seek(3);
    expect(await stream.readBuffer(4, buffer), 0);
    expect(buffer, [0, 0, 0, 0]);
  });
  test('Test fastRead', () async {
    final stream = streamProducer();
    final buffer = await stream.fastRead(2);
    expect(buffer, [1, 2]);
    expect(await stream.readByte(), 3);
  });
  test('Test fastRead after end', () async {
    final stream = streamProducer();
    await stream.seek(3);
    final buffer = await stream.fastRead(4);
    expect(buffer.isEmpty, true);
  });
}
