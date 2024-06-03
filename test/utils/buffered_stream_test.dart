import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_pdf_reader/src/utils/byte_stream.dart';
import 'package:dart_pdf_reader/src/utils/cache/buffered_random_access_stream.dart';
import 'package:dart_pdf_reader/src/utils/file_stream.dart';
import 'package:test/test.dart';

import 'stream_test.dart';
import 'test_utils.dart';

void main() {
  group('FileStream tests', () {
    late final File testFile;
    late RandomAccessFile testRandomAccessFile;
    late BufferedRandomAccessStream sut;

    setUpAll(() async {
      testFile = await createTempFile(suffix: '.dat');
      await testFile.writeAsBytes([1, 2, 3]);
    });

    setUp(() async {
      testRandomAccessFile = await testFile.open();
      sut = BufferedRandomAccessStream(
        FileStream(testRandomAccessFile),
        blockSize: 1,
        maxNumBlocks: 2,
      );
    });

    tearDown(() async {
      await testRandomAccessFile.close();
    });

    tearDownAll(() async {
      await testFile.delete();
    });

    createStreamTests(() => sut);

    test('it supports ByteStream but warns', () async {
      final logs = <String>[];
      await _overridePrint(logs, () async {
        final sut = BufferedRandomAccessStream(
          ByteStream(Uint8List.fromList([1, 2, 3])),
          blockSize: 1,
          maxNumBlocks: 2,
        );
        expect(await sut.readByte(), 1);
        expect(await sut.readByte(), 2);
        expect(await sut.readByte(), 3);
      });
      expect(logs, hasLength(1));
      expect(logs[0],
          'Warning: BufferedRandomAccessStream is not recommended for ByteStream');
    });
  });
}

Future<void> _overridePrint(List<String> log, Future<void> Function() testFn) {
  final spec = ZoneSpecification(print: (_, __, ___, String msg) {
    // Add to log instead of printing to stdout
    log.add(msg);
  });
  return Zone.current.fork(specification: spec).run(testFn);
}
