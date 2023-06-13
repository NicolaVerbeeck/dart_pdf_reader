import 'package:dart_pdf_reader/dart_pdf_reader.dart';
import 'package:test/test.dart';

import 'stream_test.dart';

void main() {
  group('ByteStream tests', () {
    late ByteStream stream;

    setUp(() {
      stream = ByteStream([1, 2, 3]);
    });

    createStreamTests(() => stream);
  });
}
