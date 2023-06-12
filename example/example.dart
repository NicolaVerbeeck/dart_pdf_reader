import 'dart:io';

import 'package:dart_pdf_reader/dart_pdf_reader.dart';
import 'package:dart_pdf_reader/src/model/pdf_page.dart';

Future<void> main(List<String> args) async {
  final inputFile = args[0];

  final stream = ByteStream(File(inputFile).readAsBytesSync());

  final stopWatch = Stopwatch()..start();
  final doc = await PDFParser(stream).parse();
  print('Parsed in ${stopWatch.elapsedMilliseconds}ms');
  stopWatch.stop();

  final catalog = await doc.catalog;
  final pages = await catalog.getPages();
  final firstPage = pages.getPageAtIndex(0);

  print(firstPage);

  print('Walking page tree bottom to top');
  PDFPageNode? node = firstPage;
  while (node != null) {
    print(await node.resources);
    node = node.parent;
  }
}
