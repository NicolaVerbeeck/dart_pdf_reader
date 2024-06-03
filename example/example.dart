// ignore_for_file: avoid_print

import 'dart:io';

import 'package:dart_pdf_reader/dart_pdf_reader.dart';
import 'package:dart_pdf_reader/src/model/pdf_page.dart';

Future<void> main(List<String> args) async {
  final inputFile = args[0];

  final stopWatch = Stopwatch()..start();
  final stream = ByteStream(File(inputFile).readAsBytesSync());
  // or stream = BufferedRandomAccessStream(FileStream(await File(inputFile).open()));
  print('Read in ${stopWatch.elapsedMilliseconds}ms');

  stopWatch.reset();
  final doc = await PDFParser(stream).parse();
  print('Parsed in ${stopWatch.elapsedMilliseconds}ms');

  stopWatch.reset();
  final catalog = await doc.catalog;
  print('Got catalog in ${stopWatch.elapsedMilliseconds}ms');

  stopWatch.reset();
  final pages = await catalog.getPages();
  print('Got pages in ${stopWatch.elapsedMilliseconds}ms');

  stopWatch.reset();
  final outlines = await catalog.getOutlines();
  print('Got outlines in ${stopWatch.elapsedMilliseconds}ms');

  stopWatch.reset();
  final firstPage = pages.getPageAtIndex(0);
  print('Got first page in ${stopWatch.elapsedMilliseconds}ms');

  print(outlines);
  print(firstPage);

  print('Walking page tree bottom to top');
  PDFPageNode? node = firstPage;
  while (node != null) {
    print(await node.resources);
    node = node.parent;
  }
  stopWatch.stop();
}
