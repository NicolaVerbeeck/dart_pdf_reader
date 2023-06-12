import 'package:dart_pdf_reader/src/model/indirect_object_table.dart';
import 'package:dart_pdf_reader/src/model/pdf_types.dart';
import 'package:dart_pdf_reader/src/parser/pdf_object_parser.dart';
import 'package:dart_pdf_reader/src/parser/token_stream.dart';
import 'package:dart_pdf_reader/src/parser/xref_reader.dart';
import 'package:dart_pdf_reader/src/utils/random_access_stream.dart';
import 'package:dart_pdf_reader/src/utils/reader_helper.dart';

class IndirectObjectParser {
  final RandomAccessStream _buffer;
  late final PDFObjectParser _parser;
  final IndirectObjectTable _objectTable;
  final TokenStream _tokenStream;

  IndirectObjectParser(this._buffer, this._objectTable)
      : _tokenStream = TokenStream(_buffer) {
    _parser = PDFObjectParser(_buffer, this);
  }

  Future<PDFObject> getObjectFor(PDFObjectReference reference) {
    final referee = _objectTable[reference.objectId];
    if (referee != null) {
      return Future.value(referee.object);
    }

    final entry = _objectTable.getObjectReferenceFor(reference.objectId)!;
    return readObjectAt(entry);
  }

  Future<PDFIndirectObject> readObjectAt(XRefEntry entry) async {
    final previousPosition = await _buffer.position;
    await _buffer.seek(entry.offset);

    await ReaderHelper.readObjectHeader(_tokenStream);
    await ReaderHelper.skipUntilFirstNonWhitespace(_tokenStream);

    final object = await _parser.parse();
    await _buffer.seek(previousPosition);
    final reference = PDFIndirectObject(
      object: object,
      generationNumber: entry.generation,
      objectId: entry.id,
    );
    _objectTable.put(entry.id, reference);
    return reference;
  }
}
