import 'dart:typed_data';

import 'package:dart_pdf_reader/src/utils/filter/direct_byte_stream.dart';
import 'package:test/test.dart';

void main() {
  group('Direct byte stream tests', () {
    group('ByteInputStream tests', () {
      test('Test readByte', () {
        final stream = ByteInputStream(Uint8List.fromList([1, 2, 3]));
        expect(stream.readByte(), 1);
        expect(stream.readByte(), 2);
        expect(stream.readByte(), 3);
      });
      test('Test readByte outside range', () {
        final stream = ByteInputStream(Uint8List.fromList([1, 2, 3]));
        expect(stream.readByte(), 1);
        expect(stream.readByte(), 2);
        expect(stream.readByte(), 3);
        expect(() => stream.readByte(), throwsException);
      });
      test('Test readFully', () {
        final stream = ByteInputStream(Uint8List.fromList([1, 2, 3]));
        final current = Uint8List(3);
        stream.readFully(current, 0, 3);
        expect(current, [1, 2, 3]);
      });
      test('Test readFully part', () {
        final stream = ByteInputStream(Uint8List.fromList([1, 2, 3]));
        final current = Uint8List(2);
        stream.readFully(current, 0, 2);
        expect(current, [1, 2]);
      });
      test('Test readFully part to offset', () {
        final stream = ByteInputStream(Uint8List.fromList([1, 2, 3]));
        final current = Uint8List(3);
        stream.readFully(current, 1, 2);
        expect(current, [0, 1, 2]);
      });
      test('Test read mixed', () {
        final stream = ByteInputStream(Uint8List.fromList([1, 2, 3]));
        expect(stream.readByte(), 1);
        final current = Uint8List(2);
        stream.readFully(current, 0, 2);
        expect(current, [2, 3]);
      });
      test('Test readFully out of range', () {
        final stream = ByteInputStream(Uint8List.fromList([1, 2, 3]));
        final current = Uint8List(4);
        expect(() => stream.readFully(current, 0, 4), throwsException);
      });
      test('Test readBytesToInt width 1', () {
        final stream = ByteInputStream(Uint8List.fromList([1, 2, 3]));
        expect(stream.readBytesToInt(1), 1);
        expect(stream.readBytesToInt(1), 2);
        expect(stream.readBytesToInt(1), 3);
      });
      test('Test readBytesToInt width 2', () {
        final stream = ByteInputStream(Uint8List.fromList([1, 2, 3, 4]));
        expect(stream.readBytesToInt(2), 0x0102);
        expect(stream.readBytesToInt(2), 0x0304);
      });
      test('Test readBytesToInt width 3', () {
        final stream = ByteInputStream(Uint8List.fromList([1, 2, 3, 4]));
        expect(stream.readBytesToInt(3), 0x010203);
        expect(stream.readByte(), 4);
      });
      test('Test readBytesToInt width 4', () {
        final stream = ByteInputStream(Uint8List.fromList([1, 2, 3, 4]));
        expect(stream.readBytesToInt(4), 0x01020304);
      });
    });
    group('ByteOutputStream tests', () {
      test('Test empty zero capacity', () {
        expect(ByteOutputStream(0).getBytes(), const <int>[]);
      });
      test('Test empty nonzero capacity', () {
        expect(ByteOutputStream(10).getBytes(), const <int>[]);
      });
      test('Test write', () {
        final stream = ByteOutputStream(10);
        stream.write(1);
        stream.write(2);
        stream.write(3);
        expect(stream.getBytes(), [1, 2, 3]);
      });
      test('Test write increase capacity', () {
        final stream = ByteOutputStream(1);
        stream.write(1);
        stream.write(2);
        stream.write(3);
        expect(stream.getBytes(), [1, 2, 3]);
      });
      test('Test writeAll', () {
        final stream = ByteOutputStream(10);
        stream.writeAll(Uint8List.fromList([1, 2, 3]));
        expect(stream.getBytes(), [1, 2, 3]);
      });
      test('Test writeAll increase capacity', () {
        final stream = ByteOutputStream(1);
        stream.writeAll(Uint8List.fromList([1, 2, 3]));
        expect(stream.getBytes(), [1, 2, 3]);
      });
      test('Test mixed write increase capacity', () {
        final stream = ByteOutputStream(1);
        stream.write(1);
        stream.writeAll(Uint8List.fromList([1, 2, 3]));
        expect(stream.getBytes(), [1, 1, 2, 3]);
      });
    });
  });
}
