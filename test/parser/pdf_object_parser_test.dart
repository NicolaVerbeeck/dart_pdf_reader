import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_pdf_reader/src/error/exceptions.dart';
import 'package:dart_pdf_reader/src/model/indirect_object_table.dart';
import 'package:dart_pdf_reader/src/model/pdf_types.dart';
import 'package:dart_pdf_reader/src/parser/indirect_object_parser.dart';
import 'package:dart_pdf_reader/src/parser/pdf_object_parser.dart';
import 'package:dart_pdf_reader/src/parser/xref_reader.dart';
import 'package:dart_pdf_reader/src/utils/byte_stream.dart';
import 'package:dart_pdf_reader/src/utils/random_access_stream.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

part 'pdf_array_parser.dart';

part 'pdf_basic_parser.dart';

part 'pdf_dictionary_parser.dart';

part 'pdf_object_ref_parser.dart';

part 'pdf_object_string_parser.dart';

part 'pdf_stream_parser.dart';

PDFObjectParser createParserFromString(
  String string, [
  IndirectObjectParser? indirectObjectParser,
]) {
  return createParser(
    ByteStream(Uint8List.fromList(utf8.encode(string))),
    indirectObjectParser,
  );
}

PDFObjectParser createParser(
  RandomAccessStream stream, [
  IndirectObjectParser? indirectObjectParser,
]) {
  indirectObjectParser ??=
      IndirectObjectParser(stream, IndirectObjectTable(const XRefTable([])));
  return PDFObjectParser(stream, indirectObjectParser);
}

void main() {
  group('PDF Object Parser', () {
    stringParserTests();
    dictionaryParserTests();
    basicParserTests();
    arrayParserTests();
    objectRefParserTests();
    streamParserTests();
  });
}
