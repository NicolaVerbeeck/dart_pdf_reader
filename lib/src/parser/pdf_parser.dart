import 'package:dart_pdf_reader/src/model/indirect_object_table.dart';
import 'package:dart_pdf_reader/src/model/pdf_document.dart';
import 'package:dart_pdf_reader/src/model/pdf_types.dart';
import 'package:dart_pdf_reader/src/parser/indirect_object_parser.dart';
import 'package:dart_pdf_reader/src/parser/object_resolver.dart';
import 'package:dart_pdf_reader/src/parser/pdf_object_parser.dart';
import 'package:dart_pdf_reader/src/parser/xref_reader.dart';
import 'package:dart_pdf_reader/src/utils/random_access_stream.dart';
import 'package:dart_pdf_reader/src/utils/reader_helper.dart';

/// Parses a PDF document from a [RandomAccessStream].
class PDFParser {
  /// The buffer to read from
  final RandomAccessStream _buffer;

  /// Creates a new PDF parser which uses the given [_buffer]
  /// Closing the buffer will cause the returned [PDFDocument] to be in an
  /// indeterminate state.
  PDFParser(this._buffer);

  /// Parses the PDF document from the stream
  /// The document is lazily parsed, only the absolute minimum is parsed, other
  /// items are parsed on demand. This means closing the stream will break
  /// reading items in the returned [PDFDocument].
  Future<PDFDocument> parse() async {
    final (mainXRef, parsedXRefTrailer) = await XRefReader(_buffer).parseXRef();
    final table = IndirectObjectTable(mainXRef);
    final objectParser = IndirectObjectParser(_buffer, table);

    PDFDictionary? mainTrailer = null;
    var first = true;
    while (true) {
      final trailer = (first && parsedXRefTrailer != null)
          ? parsedXRefTrailer
          : await _parseTrailer(objectParser);
      mainTrailer ??= trailer;
      final prev = trailer[const PDFName('Prev')] as PDFNumber?;
      if (prev == null) break;
      await _buffer.seek(prev.toInt());

      await XRefReader(_buffer).parseXRefTableInto(mainXRef);
    }

    return PDFDocument(
      mainTrailer: mainTrailer,
      objectResolver: ObjectResolver(objectParser, table),
    );
  }

  Future<PDFDictionary> _parseTrailer(IndirectObjectParser parser) async {
    final line = await ReaderHelper.readLineSkipEmpty(_buffer);
    if (line != 'trailer') {
      throw Exception('Expected \'trailer\'');
    }
    return await PDFObjectParser(_buffer, parser).parse() as PDFDictionary;
  }
}
