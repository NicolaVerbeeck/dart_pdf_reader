import 'dart:convert';

import 'package:dart_pdf_reader/src/error/exceptions.dart';
import 'package:dart_pdf_reader/src/model/indirect_object_table.dart';
import 'package:dart_pdf_reader/src/model/pdf_types.dart';
import 'package:dart_pdf_reader/src/parser/indirect_object_parser.dart';
import 'package:dart_pdf_reader/src/parser/pdf_object_parser.dart';
import 'package:dart_pdf_reader/src/parser/xref_reader.dart';
import 'package:dart_pdf_reader/src/utils/byte_stream.dart';
import 'package:dart_pdf_reader/src/utils/random_access_stream.dart';
import 'package:test/test.dart';

part 'pdf_dictionary_parser.dart';
part 'pdf_object_string_parser.dart';

PDFObjectParser createParserFromString(String string) {
  return createParser(ByteStream(utf8.encode(string)));
}

PDFObjectParser createParser(RandomAccessStream stream) {
  final indirectObjectParser =
      IndirectObjectParser(stream, IndirectObjectTable(const XRefTable([])));
  return PDFObjectParser(stream, indirectObjectParser);
}

void main() {
  group('PDF Object Parser', () {
    stringParserTests();
    dictionaryParserTests();
  });
}
