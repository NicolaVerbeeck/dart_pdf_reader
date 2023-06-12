import 'package:dart_pdf_reader/src/model/pdf_types.dart';
import 'package:dart_pdf_reader/src/utils/random_access_stream.dart';
import 'package:dart_pdf_reader/src/utils/reader_helper.dart';
import 'package:meta/meta.dart';

@immutable
class XRefTable {
  final List<XRefSubsection> sections;

  XRefTable(this.sections);

  @override
  String toString() {
    return 'XRefTable{sections: $sections}';
  }
}

class XRefReader {
  final RandomAccessStream stream;

  XRefReader(this.stream);

  Future<XRefTable> parseXRef() async {
    final offset = await _findXRefOffset();
    await stream.seek(offset);
    final sectionReader = XRefSectionReader();
    final sections = await sectionReader.readSubsections(stream);

    return XRefTable(sections);
  }

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
      throw Exception('%%EOF not found');
    }
    return int.parse(lines[eofIndex - 1]);
  }
}

class XRefSectionReader {
  Future<List<XRefSubsection>> readSubsections(
      RandomAccessStream stream) async {
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
      RandomAccessStream stream) async {
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
      String firstLine, RandomAccessStream stream) async {
    final parts = firstLine.split(' ');
    assert(parts.length == 2);

    final int startIndex = int.parse(parts[0]);
    final int numEntries = int.parse(parts[1]);

    final entries = <XRefEntry>[];
    final lineBytes = List.filled(20, 0);
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

  @override
  String toString() {
    return 'XRefSection{previousXRefOffset: $dict, entries: $entries}';
  }
}

@immutable
class XRefEntry {
  final int id;
  final int offset;
  final int generation;
  final bool free;

  const XRefEntry({
    required this.id,
    required this.offset,
    required this.generation,
    required this.free,
  });

  @override
  String toString() {
    return 'XRefEntry{id: $id, offset: $offset, generation: $generation, free: $free}';
  }
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

  @override
  String toString() {
    return 'XRefSubsection{startIndex: $startIndex, numEntries: $numEntries, entries: $entries, endIndex: $endIndex}';
  }

  bool hasId(int objectId) => startIndex <= objectId && objectId < endIndex;

  XRefEntry? getObject(int objectId) {
    for (final ref in entries) {
      if (ref.id == objectId) return ref;
    }
    return null;
  }
}
