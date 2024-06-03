import 'dart:io';

import 'package:dart_pdf_reader/src/utils/file_stream.dart';
import 'package:test/scaffolding.dart';

import 'stream_test.dart';
import 'test_utils.dart';

void main() {
  group('FileStream tests', () {
    late final File testFile;
    late RandomAccessFile testRandomAccessFile;
    late FileStream stream;

    setUpAll(() async {
      testFile = await createTempFile(suffix: '.dat');
      await testFile.writeAsBytes([1, 2, 3]);
    });

    setUp(() async {
      testRandomAccessFile = await testFile.open();
      stream = FileStream(testRandomAccessFile);
    });

    tearDown(() async {
      await testRandomAccessFile.close();
    });

    tearDownAll(() async {
      await testFile.delete();
    });

    createStreamTests(() => stream);
  });
}
