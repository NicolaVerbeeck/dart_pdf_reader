import 'package:meta/meta.dart';

import '../model/indirect_object_table.dart';
import '../model/pdf_constants.dart';
import '../model/pdf_document.dart';
import '../model/pdf_types.dart';
import '../utils/random_access_stream.dart';
import '../utils/reader_helper.dart';
import 'indirect_object_parser.dart';
import 'object_resolver.dart';
import 'pdf_object_parser.dart';
import 'xref_reader.dart';

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
  /// Setting [cacheObjectsHint] to `true` will cache resolved objects in memory
  Future<PDFDocument> parse({bool cacheObjectsHint = true}) async {
    final (mainXRef, parsedXRefTrailer) = await XRefReader(_buffer).parseXRef();
    final table = IndirectObjectTable(mainXRef);
    final objectParser = IndirectObjectParser(_buffer, table);

    PDFDictionary? mainTrailer;
    var first = true;
    while (true) {
      final trailer = (first && parsedXRefTrailer != null)
          ? parsedXRefTrailer
          : await parseTrailer(objectParser, _buffer);
      first = false;
      mainTrailer ??= trailer;
      final prev = trailer[PDFNames.prev] as PDFNumber?;
      if (prev == null) break;
      await _buffer.seek(prev.toInt());

      await XRefReader(_buffer).parseXRefTableInto(mainXRef);
    }

    return PDFDocument(
      mainTrailer: mainTrailer,
      objectResolver: ObjectResolver(
        objectParser,
        table,
        cacheResolvedObjects: cacheObjectsHint,
      ),
    );
  }
}

/// Parse the document trailer dictionary from [buffer]
@visibleForTesting
Future<PDFDictionary> parseTrailer(
  IndirectObjectParser parser,
  RandomAccessStream buffer,
) async {
  final line = await ReaderHelper.readWordTrimmed(buffer);
  if (line != 'trailer') {
    throw Exception('Expected \'trailer\', got: $line');
  }
  return await PDFObjectParser(buffer, parser).parse() as PDFDictionary;
}
