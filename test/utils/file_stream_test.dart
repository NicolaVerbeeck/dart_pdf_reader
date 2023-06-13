import 'dart:io';

import 'package:dart_pdf_reader/dart_pdf_reader.dart';
import 'package:dcli/dcli.dart';
import 'package:test/scaffolding.dart';

import 'stream_test.dart';

void main() {
  group('FileStream tests', () {
    late final File testFile;
    late RandomAccessFile testRandomAccessFile;
    late FileStream stream;

    setUpAll(() async {
      final fileName = createTempFile(suffix: '.dat');
      testFile = File(fileName);
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
