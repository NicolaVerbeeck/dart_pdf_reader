import 'dart:collection';
import 'dart:convert';

import 'package:charset/charset.dart';
import 'package:collection/collection.dart';
import 'package:dart_pdf_reader/dart_pdf_reader.dart';
import 'package:meta/meta.dart';

/// Base class for all PDF objects.
abstract class PDFObject {
  const PDFObject();
}

/// A PDF number object
@immutable
class PDFNumber extends PDFObject {
  /// The precision used when printing the number using [toString].
  static const int _printPrecision = 5;

  /// The epsilon used when determining if a number is close enough to an integer
  /// See [_truncate].
  static const double _epsilon = 0.000001;

  /// The value of the number.
  final num _value;

  /// Creates a new [PDFNumber] object.
  const PDFNumber(this._value) : assert(_value is int || _value is double);

  /// Creates a new [PDFNumber] object as copy from this one
  PDFNumber clone() => PDFNumber(_value);

  @override
  String toString() {
    final truncated = _truncate();
    if (truncated is int) {
      return '$truncated';
    } else {
      var r = truncated.toStringAsFixed(_printPrecision);
      if (r.contains('.')) {
        var n = r.length - 1;
        while (r[n] == '0') {
          n--;
        }
        if (r[n] == '.') {
          n--;
        }
        r = r.substring(0, n + 1);
      }
      return r;
    }
  }

  /// The integer representation of this number. If the number is not an integer,
  /// it will be truncated to the next smallest integer.
  int toInt() => _value.toInt();

  /// The double representation of this number.
  double toDouble() => _value.toDouble();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PDFNumber && _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  /// Truncates the number to an integer if it is close enough to an integer.
  num _truncate() {
    if (_value is int) {
      return _value;
    } else {
      final diff = (_value.toDouble() - _value.toInt()).abs();
      if (diff < _epsilon) {
        return _value.toInt();
      }
      return _value;
    }
  }
}

/// Literal string defined in PDF
@immutable
class PDFLiteralString extends PDFStringLike {
  /// The value of the string.
  final List<int> _value;

  /// The code points of this string. No specific encoding is assumed
  List<int> get codePoints => _value;

  /// Creates a new [PDFLiteralString] object.
  const PDFLiteralString(this._value);

  @override
  String toString() => '(${asPDFString()})';

  /// Converts the string to a dart string (best effort)
  @override
  String asString() {
    if (_isUnicode()) {
      return utf16.decode(_value);
    }
    return utf8.decode(_value);
  }

  @override
  PDFLiteralString clone() => PDFLiteralString(_value);

  bool _isUnicode() {
    if (_value.length < 2) return false;
    return _value[0] == 0xfe && _value[1] == 0xff;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PDFLiteralString &&
          const DeepCollectionEquality().equals(_value, other._value);

  @override
  int get hashCode => const DeepCollectionEquality().hash(_value);

  @override
  String asPDFString() {
    final buffer = StringBuffer();
    buffer.write('(');
    for (final byte in _value) {
      switch (byte) {
        case 0x0a: // \n Line feed (LF)
          buffer.writeCharCode(0x5c);
          buffer.writeCharCode(0x6e);
          break;
        case 0x0d: // \r Carriage return (CR)
          buffer.writeCharCode(0x5c);
          buffer.writeCharCode(0x72);
          break;
        case 0x09: // \t Horizontal tab (HT)
          buffer.writeCharCode(0x5c);
          buffer.writeCharCode(0x74);
          break;
        case 0x08: // \b Backspace (BS)
          buffer.writeCharCode(0x5c);
          buffer.writeCharCode(0x62);
          break;
        case 0x0c: // \f Form feed (FF)
          buffer.writeCharCode(0x5c);
          buffer.writeCharCode(0x66);
          break;
        case 0x28: // \( Left parenthesis
          buffer.writeCharCode(0x5c);
          buffer.writeCharCode(0x28);
          break;
        case 0x29: // \) Right parenthesis
          buffer.writeCharCode(0x5c);
          buffer.writeCharCode(0x29);
          break;
        case 0x5c: // \\ Backslash
          buffer.writeCharCode(0x5c);
          buffer.writeCharCode(0x5c);
          break;
        default:
          buffer.writeCharCode(byte);
      }
    }
    buffer.write(')');
    return buffer.toString();
  }
}

/// Base class for all PDF string like objects ([PDFLiteralString] and [PDFHexString])
abstract class PDFStringLike extends PDFObject {
  const PDFStringLike();

  /// The dart string representation of this object.
  String asString();

  /// Creates a copy of this [PDFStringLike] object
  PDFStringLike clone();

  String asPDFString();
}

/// Hex string defined in PDF
@immutable
class PDFHexString extends PDFLiteralString {
  /// Creates a new [PDFHexString] object.
  const PDFHexString(super.value);

  @override
  String toString() => asPDFString();

  @override
  PDFHexString clone() => PDFHexString(_value);

  @override
  String asPDFString() {
    final buffer = StringBuffer();
    buffer.write('<');
    for (final byte in _value) {
      buffer.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    buffer.write('>');
    return buffer.toString();
  }
}

/// PDF boolean object
@immutable
class PDFBoolean extends PDFObject {
  /// The value of the boolean.
  final bool value;

  /// Creates a new [PDFBoolean] object.
  const PDFBoolean(this.value);

  @override
  String toString() => value ? 'true' : 'false';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PDFBoolean && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// PDF null object
@immutable
class PDFNull extends PDFObject {
  /// Creates a new [PDFNull] object.
  const PDFNull();

  @override
  String toString() => 'null';

  @override
  bool operator ==(Object other) => identical(this, other) || other is PDFNull;

  @override
  int get hashCode => 0;
}

/// PDF name object. Names MUST NOT start with '/'!
@immutable
class PDFName extends PDFObject {
  /// The value of the name.
  final String _value;

  /// The raw name of the object. Does not start with leading '/'
  String get value => _value;

  /// Creates a new [PDFName] object.
  const PDFName(this._value);

  @override
  String toString() => '/$_value';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PDFName && _value == other._value;

  @override
  int get hashCode => _value.hashCode;
}

/// PDF array object
class PDFArray extends PDFObject
    with ListMixin<PDFObject>
    implements Iterable<PDFObject> {
  /// The elements of the array.
  final List<PDFObject> _elements;

  @override
  int get length => _elements.length;

  /// Creates a new [PDFArray] object.
  const PDFArray(this._elements);

  @override
  String toString() => '[${_elements.join(' ')}]';

  /// Access operator that returns the object at [index]. Throws if the index is
  /// invalid
  @override
  PDFObject operator [](int index) => _elements[index];

  @override
  void operator []=(int index, PDFObject value) =>
      throw ArgumentError('PDFArray is immutable');

  @override
  set length(int newLength) => throw ArgumentError('PDFArray is immutable');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PDFArray &&
          const DeepCollectionEquality().equals(_elements, other._elements);

  @override
  int get hashCode => const DeepCollectionEquality().hash(_elements);
}

/// PDF dictionary object
class PDFDictionary extends PDFObject {
  /// The entries of the dictionary.
  final Map<PDFName, PDFObject> entries;

  /// Creates a new [PDFDictionary] object.
  const PDFDictionary(this.entries);

  @override
  String toString() =>
      '<<${entries.entries.map((e) => '${e.key} ${e.value}').join(' ')}>>';

  /// Accessor operator that returns the object for [key] if any
  PDFObject? operator [](PDFName key) => entries[key];

  /// Checks if the dictionary has an entry for [key]
  bool has(PDFName key) => entries.containsKey(key);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PDFDictionary &&
          const DeepCollectionEquality().equals(entries, other.entries);

  @override
  int get hashCode => const DeepCollectionEquality().hash(entries);
}

/// A reference to another PDF object
@immutable
class PDFObjectReference extends PDFObject {
  /// The object id of the referenced object.
  final int objectId;

  /// The generation number of the referenced object.
  final int generationNumber;

  /// Creates a new [PDFObjectReference] object.
  const PDFObjectReference({
    required this.objectId,
    this.generationNumber = 0,
  });

  @override
  String toString() => '$objectId $generationNumber R';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PDFObjectReference &&
          objectId == other.objectId &&
          generationNumber == other.generationNumber;

  @override
  int get hashCode => objectId.hashCode ^ generationNumber.hashCode;
}

/// A PDF content stream command
@immutable
class PDFCommand extends PDFObject {
  final String command;

  const PDFCommand(this.command);

  @override
  String toString() => command;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PDFCommand && command == other.command;

  @override
  int get hashCode => command.hashCode;
}

/// PDF stream object. Streams do not eagerly read the data from the data source
/// but instead provide a [read] method that can be used to read the data.
/// Closing the stream before reading data will result in an error
@immutable
class PDFStreamObject extends PDFObject {
  /// The dictionary of the stream.
  final PDFDictionary dictionary;

  /// The data source of the stream.
  final RandomAccessStream dataSource;

  /// The offset to read from within the [dataSource].
  final int offset;

  /// The length in raw bytes of the stream.
  final int length;

  /// Flag indicating if the stream is likely to contain binary data.
  final bool isBinary;

  const PDFStreamObject({
    required this.dictionary,
    required this.dataSource,
    required this.offset,
    required this.length,
    required this.isBinary,
  });

  /// Reads the raw bytes of this stream. This means no filtering is applied.
  /// When [read] returns, the stream will be positioned back to where it was
  /// before [read] started
  Future<List<int>> read() async {
    final pos = await dataSource.position;
    await dataSource.seek(offset);
    final into = List<int>.filled(length, 0);
    await dataSource.readBuffer(length, into);
    await dataSource.seek(pos);
    return into;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PDFStreamObject &&
          dictionary == other.dictionary &&
          dataSource == other.dataSource &&
          offset == other.offset &&
          length == other.length &&
          isBinary == other.isBinary;

  @override
  int get hashCode =>
      dictionary.hashCode ^
      dataSource.hashCode ^
      offset.hashCode ^
      length.hashCode ^
      isBinary.hashCode;
}

/// PDF indirect object. This object contains the reference to where the object
/// is located in the PDF file (like [PDFObjectReference]) but it also contains
/// the actual object read from the PDF file
@immutable
class PDFIndirectObject extends PDFObject {
  /// The object this indirect object is referencing.
  final PDFObject object;

  /// The object id of the referenced object.
  final int objectId;

  /// The generation number of the referenced object.
  final int generationNumber;

  const PDFIndirectObject({
    required this.object,
    required this.objectId,
    required this.generationNumber,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PDFIndirectObject &&
          object == other.object &&
          objectId == other.objectId &&
          generationNumber == other.generationNumber;

  @override
  int get hashCode =>
      object.hashCode ^ objectId.hashCode ^ generationNumber.hashCode;
}
