import 'dart:typed_data';

import 'package:dart_pdf_reader/dart_pdf_reader.dart';
import 'package:test/test.dart';

import 'stream_test.dart';

void main() {
  group('ByteStream tests', () {
    late ByteStream stream;

    setUp(() {
      stream = ByteStream(Uint8List.fromList([1, 2, 3]));
    });

    createStreamTests(() => stream);

    test('Test bytestream of fastRead result', () async {
      final stream = ByteStream(Uint8List.fromList([1, 2, 3]));
      await stream.seek(1);
      final res = await stream.fastRead(2);
      final newBuffer = ByteStream(res);
      final endRes = await newBuffer.fastRead(1);
      expect(endRes, [2]);
    });
  });
}
