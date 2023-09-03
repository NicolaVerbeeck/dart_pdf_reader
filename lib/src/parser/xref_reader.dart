import 'dart:typed_data';

import 'package:dart_pdf_reader/src/error/exceptions.dart';
import 'package:dart_pdf_reader/src/model/indirect_object_table.dart';
import 'package:dart_pdf_reader/src/model/pdf_types.dart';
import 'package:dart_pdf_reader/src/parser/indirect_object_parser.dart';
import 'package:dart_pdf_reader/src/parser/object_resolver.dart';
import 'package:dart_pdf_reader/src/parser/pdf_object_parser.dart';
import 'package:dart_pdf_reader/src/parser/token_stream.dart';
import 'package:dart_pdf_reader/src/utils/filter/direct_byte_stream.dart';
import 'package:dart_pdf_reader/src/utils/random_access_stream.dart';
import 'package:dart_pdf_reader/src/utils/reader_helper.dart';
import 'package:meta/meta.dart';

@immutable
class XRefTable {
  final List<XRefSubsection> sections;

  const XRefTable(this.sections);

  // coverage:ignore-start
  @override
  String toString() {
    return 'XRefTable{sections: $sections}';
  }
// coverage:ignore-end
}

class XRefReader {
  final RandomAccessStream stream;

  XRefReader(this.stream);

  /// Reads the xref information from the stream
  ///
  /// Returns the table as the first element of the record
  /// and the trailer as the second element if the trailer was required to
  /// parse the xref table
  Future<(XRefTable, PDFDictionary?)> parseXRef() async {
    final offset = await _findXRefOffset();
    await stream.seek(offset);
    final sectionReader = XRefSectionReader();
    final sections = await sectionReader.readSubsections(stream);
    if (sections.isEmpty) {
      // No xref entries found
      await stream.seek(offset);
      final line = await ReaderHelper.readLineSkipEmpty(stream);
      if (line == null || !RegExp(r'\d+ \d+ obj').hasMatch(line)) {
        throw const ParseException('Expected \'trailer\'');
      }
      await stream.seek(offset);
      return _parseXRefAndTrailerFromStreamAtObject();
    }

    return (XRefTable(sections), null);
  }

  /// Parse additional subsections starting at the current stream position
  /// into the given [table]
  Future<void> parseXRefTableInto(XRefTable table) async {
    final sectionReader = XRefSectionReader();
    final sections = await sectionReader.readSubsections(stream);
    table.sections.addAll(sections);
  }

  Future<int> _findXRefOffset() async {
    await stream.seek(await stream.length - 100);
    final lines = <String>[];
    String? line;
    while ((line = await ReaderHelper.readLine(stream)) != null) {
      line = ReaderHelper.removeComments(line!);
      if (line.isNotEmpty) {
        lines.add(line);
      }
    }
    final eofIndex = lines.indexOf('%%EOF');
    if (eofIndex == -1 || eofIndex == 0) {
      throw const ParseException('%%EOF not found');
    }
    return int.parse(lines[eofIndex - 1]);
  }

  Future<(XRefTable, PDFDictionary?)> _parseXRefAndTrailerFromCompressedStream(
    PDFDictionary dictionary,
    PDFStreamObject stream,
  ) async {
    final size =
        (dictionary.entries[const PDFName('Size')] as PDFNumber).toInt();
    final index = dictionary.entries[const PDFName('Index')] as PDFArray? ??
        PDFArray([const PDFNumber(0), PDFNumber(size)]);

    final w = dictionary.entries[const PDFName('W')] as PDFArray?;
    if (w == null) throw const ParseException('Xref stream requires W entry');
    if (w.length != 3) {
      throw const ParseException(
          'Xref stream requires W entry with 3 elements');
    }
    final firstW = (w[0] as PDFNumber).toInt();
    final secondW = (w[1] as PDFNumber).toInt();
    final thirdW = (w[2] as PDFNumber).toInt();

    final streamData = await stream.read(const _FakeObjectResolver());
    final table = _parseXRefFromCompressedStream(
      index,
      streamData,
      firstW,
      secondW,
      thirdW,
    );
    final trailerEntries = <PDFName, PDFObject>{}..addAll(dictionary.entries);
    trailerEntries.remove(const PDFName('DecodeParms'));
    trailerEntries.remove(const PDFName('Filter'));
    trailerEntries.remove(const PDFName('Length'));
    trailerEntries.remove(const PDFName('Prev'));

    final prev = dictionary[const PDFName('Prev')] as PDFNumber?;
    if (prev != null) {
      await this.stream.seek(prev.toInt());
      final (newXRef, _) = await _parseXRefAndTrailerFromStreamAtObject();
      table.sections.addAll(newXRef.sections);
    }
    return (table, PDFDictionary(trailerEntries));
  }

  XRefTable _parseXRefFromCompressedStream(
    PDFArray index,
    Uint8List streamData,
    int firstW,
    int secondW,
    int thirdW,
  ) {
    final sections = <XRefSubsection>[];
    final stream = ByteInputStream(streamData);
    for (var idx = 0; idx < index.length; idx += 2) {
      var start = (index[idx] as PDFNumber).toInt();
      var length = (index[idx + 1] as PDFNumber).toInt();

      final entries = <XRefEntry>[];
      while (length-- > 0) {
        final type = (firstW == 0) ? 1 : stream.readBytesToInt(firstW);
        final field2 = (secondW == 0) ? 0 : stream.readBytesToInt(secondW);
        final field3 = (thirdW == 0) ? 0 : stream.readBytesToInt(thirdW);

        final XRefEntry entry;
        switch (type) {
          case 0:
            entry = XRefEntry(
                id: start, offset: field2, generation: field3, free: true);
            break;
          case 1:
            entry = XRefEntry(
                id: start, offset: field2, generation: field3, free: false);
            break;
          case 2:
            entry = XRefEntry(
              id: start,
              offset: field3,
              generation: 0,
              free: false,
              compressedObjectStreamId: field2,
            );
            break;
          default:
            throw ParseException(
                'Invalid XRef entry type: $type (type 2 not supported for now). Id: $start, offset: $field3');
        }
        entries.add(entry);
        ++start;
      }
      sections.add(XRefSubsection(
          startIndex: (index[idx] as PDFNumber).toInt(),
          numEntries: (index[idx + 1] as PDFNumber).toInt(),
          entries: entries,
          endIndex: (index[idx] as PDFNumber).toInt() +
              (index[idx + 1] as PDFNumber).toInt()));
    }
    return XRefTable(sections);
  }

  Future<(XRefTable, PDFDictionary?)>
      _parseXRefAndTrailerFromStreamAtObject() async {
    await ReaderHelper.skipObjectHeader(TokenStream(stream));
    final xrefStream = (await PDFObjectParser(
      stream,
      IndirectObjectParser(stream, IndirectObjectTable(const XRefTable([]))),
    ).parse()) as PDFStreamObject;
    if (xrefStream.dictionary.entries[const PDFName('Type')] !=
        const PDFName('XRef')) {
      throw const ParseException('Compressed xref stream is of wrong type');
    }
    return _parseXRefAndTrailerFromCompressedStream(
        xrefStream.dictionary, xrefStream);
  }
}

class XRefSectionReader {
  Future<List<XRefSubsection>> readSubsections(
    RandomAccessStream stream,
  ) async {
    final subsections = <XRefSubsection>[];
    final line = await ReaderHelper.readLineSkipEmpty(stream);
    if (line == 'xref') {
      final subsection =
          await _XRefSubsectionReader().readXRefSubsections(stream);
      subsections.addAll(subsection);
    }

    return subsections;
  }
}

class _XRefSubsectionReader {
  Future<List<XRefSubsection>> readXRefSubsections(
    RandomAccessStream stream,
  ) async {
    final subsections = <XRefSubsection>[];
    while (true) {
      final lastPos = await stream.position;
      final line = await ReaderHelper.readLineSkipEmpty(stream);
      if (line == null) {
        break;
      }
      final match = RegExp(r'\d+\s+\d+').firstMatch(line);
      if (match == null || match.end != line.length) {
        await stream.seek(lastPos);
        break;
      }
      subsections.add(await readXRefSubsection(line, stream));
    }
    return subsections;
  }

  Future<XRefSubsection> readXRefSubsection(
    String firstLine,
    RandomAccessStream stream,
  ) async {
    final parts = firstLine.split(' ');
    assert(parts.length == 2);

    final int startIndex = int.parse(parts[0]);
    final int numEntries = int.parse(parts[1]);

    final entries = <XRefEntry>[];
    final lineBytes = Uint8List(20);
    int id = startIndex;
    for (int i = 0; i < numEntries; i++) {
      await stream.readBuffer(20, lineBytes);

      final int offset =
          int.parse(String.fromCharCodes(lineBytes.getRange(0, 10)));
      final int generation =
          int.parse(String.fromCharCodes(lineBytes.getRange(11, 17)));
      final free = lineBytes[17] == 0x66;

      entries.add(XRefEntry(
        id: id++,
        offset: offset,
        generation: generation,
        free: free,
      ));
    }

    return XRefSubsection(
      startIndex: startIndex,
      numEntries: numEntries,
      entries: entries,
      endIndex: id,
    );
  }
}

@immutable
class XRefSection {
  final PDFDictionary dict;
  final List<XRefSubsection> entries;

  const XRefSection({
    required this.dict,
    required this.entries,
  });

  // coverage:ignore-start
  @override
  String toString() {
    return 'XRefSection{previousXRefOffset: $dict, entries: $entries}';
  }
// coverage:ignore-end
}

@immutable
class XRefEntry {
  final int id;
  final int offset;
  final int generation;
  final bool free;
  final int? compressedObjectStreamId;

  const XRefEntry({
    required this.id,
    required this.offset,
    required this.generation,
    required this.free,
    this.compressedObjectStreamId,
  });

  // coverage:ignore-start
  @override
  String toString() {
    return 'XRefEntry{id: $id, offset: $offset, generation: $generation, free: $free, compressedObjectStreamId: $compressedObjectStreamId}';
  }
// coverage:ignore-end
}

@immutable
class XRefSubsection {
  final int startIndex;
  final int numEntries;
  final List<XRefEntry> entries;
  final int endIndex;

  const XRefSubsection({
    required this.startIndex,
    required this.numEntries,
    required this.entries,
    required this.endIndex,
  });

  // coverage:ignore-start
  @override
  String toString() {
    return 'XRefSubsection{startIndex: $startIndex, numEntries: $numEntries, entries: $entries, endIndex: $endIndex}';
  }

  // coverage:ignore-end

  bool hasId(int objectId) => startIndex <= objectId && objectId < endIndex;

  XRefEntry? getObject(int objectId) {
    for (final ref in entries) {
      if (ref.id == objectId) return ref;
    }
    return null;
  }
}

class _FakeObjectResolver implements ObjectResolver {
  const _FakeObjectResolver();

  @override
  Future<PDFObject?> getObject(int id) => Future.value(null);

  @override
  Future<T?> resolve<T extends PDFObject>(PDFObject? toResolve) =>
      Future.value(toResolve as T);
}
