import 'package:dart_pdf_reader/src/error/exceptions.dart';
import 'package:dart_pdf_reader/src/model/indirect_object_table.dart';
import 'package:dart_pdf_reader/src/model/pdf_types.dart';
import 'package:dart_pdf_reader/src/parser/object_resolver.dart';
import 'package:dart_pdf_reader/src/parser/pdf_object_parser.dart';
import 'package:dart_pdf_reader/src/parser/token_stream.dart';
import 'package:dart_pdf_reader/src/parser/xref_reader.dart';
import 'package:dart_pdf_reader/src/utils/byte_stream.dart';
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
    if (entry.compressedObjectStreamId != null) {
      return _readFromCompressedStream(entry);
    }
    await _buffer.seek(entry.offset);

    await ReaderHelper.skipObjectHeader(_tokenStream);
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

  Future<PDFIndirectObject> _readFromCompressedStream(XRefEntry entry) async {
    final resolver = ObjectResolver(this, _objectTable);

    final compressedContainer =
        _objectTable.getObjectReferenceFor(entry.compressedObjectStreamId!)!;
    final stream =
        (await readObjectAt(compressedContainer)).object as PDFStreamObject;
    assert(stream.dictionary[const PDFName('Type')] == const PDFName('ObjStm'));
    if (stream.dictionary.has(const PDFName('Extends'))) {
      throw const ParseException(
          'Extends on compressed stream not supported yet');
    }

    final streamData = await stream.read(resolver);
    final internalStream = ByteStream(streamData);
    final tokenStream = TokenStream(internalStream);

    final first = (await resolver
            .resolve<PDFNumber>(stream.dictionary[const PDFName('First')]))!
        .toInt();

    final n = (await resolver
            .resolve<PDFNumber>(stream.dictionary[const PDFName('N')]))!
        .toInt();

    final objectNumbers = List<int>.filled(n, 0);
    final addresses = List<int>.filled(n, 0);
    for (int k = 0; k < n; ++k) {
      objectNumbers[k] = await ReaderHelper.readNumber(tokenStream);
      final address = await ReaderHelper.readNumber(tokenStream);
      addresses[k] = address + first;
    }
    PDFObject? returnObject;
    for (int k = 0; k < n; ++k) {
      await internalStream.seek(addresses[k]);
      final object = await PDFObjectParser(internalStream, this).parse();
      if (objectNumbers[k] == entry.id) {
        returnObject = object;
      }
      _objectTable.put(
        objectNumbers[k],
        PDFIndirectObject(
          object: object,
          objectId: objectNumbers[k],
          generationNumber: 0,
        ),
      );
    }

    final reference = PDFIndirectObject(
      object: returnObject!,
      generationNumber: entry.generation,
      objectId: entry.id,
    );
    return reference;
  }
}
