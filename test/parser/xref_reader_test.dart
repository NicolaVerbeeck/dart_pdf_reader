import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_pdf_reader/dart_pdf_reader.dart';
import 'package:dart_pdf_reader/src/parser/xref_reader.dart';
import 'package:test/test.dart';

const _normalTrailer = '''
%randomdata
xref
1 19
0000000016 00000 n\r
0000190137 00000 n\r
0000190405 00000 n\r
0000190454 00000 n\r
0000190591 00000 n\r
0000190631 00000 n\r
0000190874 00000 n\r
0000191866 00000 n\r
0000191971 00000 n\r
0000197939 00000 n\r
0000198518 00000 n\r
0000198897 00000 n\r
0000199330 00000 n\r
0000199825 00000 n\r
0000200577 00000 n\r
0000206645 00000 n\r
0000207066 00000 n\r
0000207457 00000 n\r
0000207758 00000 n\r
trailer
<</Size 19>>
startxref
11
%%EOF
''';

const _indirectTrailer = '''
%randomdata
15 0 obj
<</Filter/ASCIIHexDecode/Type/XRef/W[1 2 2]/Size 16/Root 13 0 R/Info 10 0 R/ID[<2A8E3741EE74B7B1F9A0870B72B9C9A6><2A8E3741EE74B7B1F9A0870B72B9C9A6>]/Length 160>>
stream
000000ffff0200090003010a8f000001000f00000200090002010c630000010aa30000020009000102000900000113dc0000010c7600000113890000010d5a000001139e00000114ec00000115000000
endstream
endobj
startxref
11
%%EOF
''';

void main() {
  group('XRefReader tests', () {
    test('Test normal xref', () async {
      final data = Uint8List.fromList(utf8.encode(_normalTrailer));
      final stream = ByteStream(data);
      final reader = XRefReader(stream);
      final (table, dict) = await reader.parseXRef();
      expect(dict, isNull);
      expect(table, isNotNull);
      expect(table.sections.length, 1);
      final section = table.sections[0];
      expect(section.startIndex, 1);
      expect(section.endIndex, 20);
      expect(section.entries.length, 19);
      expect(section.entries[0].offset, 16);
      expect(section.entries[18].offset, 207758);
      expect(section.entries[18].id, 19);
      expect(section.hasId(12), true);
      expect(section.getObject(12)!.id, 12);
      expect(section.getObject(12)!.offset, 198897);
    });
    test('Test normal parse into', () async {
      final data = Uint8List.fromList(utf8.encode(_normalTrailer));
      final stream = ByteStream(data);
      await stream.seek(11);
      final reader = XRefReader(stream);
      // ignore: prefer_const_constructors
      final table = XRefTable([]);
      await reader.parseXRefTableInto(table);

      expect(table.sections.length, 1);
      final section = table.sections[0];
      expect(section.startIndex, 1);
      expect(section.endIndex, 20);
      expect(section.entries.length, 19);
      expect(section.entries[0].offset, 16);
      expect(section.entries[18].offset, 207758);
      expect(section.entries[18].id, 19);
      expect(section.hasId(12), true);
      expect(section.getObject(12)!.id, 12);
      expect(section.getObject(12)!.offset, 198897);
    });
    test('Test xref eof not found', () async {
      final data = Uint8List.fromList(
          utf8.encode(_normalTrailer.substring(0, _normalTrailer.length - 5)));
      final stream = ByteStream(data);
      final reader = XRefReader(stream);
      expect(() => reader.parseXRef(), throwsA(isA<ParseException>()));
    });
    test('Test xref indirect trailer', () async {
      final data = Uint8List.fromList(utf8.encode(_indirectTrailer));
      final stream = ByteStream(data);
      final reader = XRefReader(stream);
      final (table, dict) = await reader.parseXRef();
      expect(dict, isNotNull);
      expect(table, isNotNull);
      expect(table.sections.length, 1);
      final section = table.sections[0];
      expect(section.entries.length, 16);
      expect(section.entries[0].generation, 65535);
      expect(section.entries[15].offset, 5376);
      expect(section.entries[7].offset, 1);
      expect(section.entries[7].id, 7);
      expect(section.entries[7].compressedObjectStreamId, 9);
      expect(section.hasId(5), true);
    });
  });
}
