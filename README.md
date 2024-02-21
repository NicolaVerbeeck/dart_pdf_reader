[![Version](https://img.shields.io/pub/v/dart_pdf_reader.svg)](https://pub.dev/packages/dart_pdf_reader) [![codecov](https://codecov.io/gh/NicolaVerbeeck/dart_pdf_reader/graph/badge.svg?token=20CAT9JC3Y)](https://codecov.io/gh/NicolaVerbeeck/dart_pdf_reader)[![OpenSSF Scorecard](https://api.securityscorecards.dev/projects/github.com/NicolaVerbeeck/dart_pdf_reader/badge)](https://securityscorecards.dev/viewer/?uri=github.com/NicolaVerbeeck/dart_pdf_reader)

## Features

'Simple' PDF reader package. Does not do a lot of interpretation of the data
that is being read, but it does provide a way to read the data from a PDF file

## Getting started

1) Create `RandomAccessStream` from either bytes `ByteStream` or file `FileStream`
2) Create `PDFParser` using the stream from step 1
3) Read the PDF file using the `PDFParser` from step 2 `await parser.parse()`

## Example
```dart
final stream = ByteStream(File(inputFile).readAsBytesSync());
final doc = await PDFParser(stream).parse();

final catalog = await doc.catalog;
final pages = await catalog.getPages();
final outlines = await catalog.getOutlines();
final firstPage = pages.getPageAtIndex(0);
```