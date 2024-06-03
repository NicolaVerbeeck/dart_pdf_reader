import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:charset/charset.dart';
import 'package:dart_pdf_reader/src/error/exceptions.dart';
import 'package:dart_pdf_reader/src/model/pdf_types.dart';
import 'package:dart_pdf_reader/src/parser/object_resolver.dart';
import 'package:dart_pdf_reader/src/utils/byte_stream.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

void main() {
  group('PDF Types tests', () {
    group('PDFNUmber tests', () {
      test('Test clone PDFNumber int', () {
        const pdfNumber = PDFNumber(1);
        final pdfNumberClone = pdfNumber.clone();
        expect(pdfNumberClone, isNotNull);
        expect(pdfNumberClone, isNot(same(pdfNumber)));
        expect(pdfNumberClone, equals(pdfNumber));
      });
      test('Test clone PDFNUmber double', () {
        const pdfNumber = PDFNumber(1.0);
        final pdfNumberClone = pdfNumber.clone();
        expect(pdfNumberClone, isNotNull);
        expect(pdfNumberClone, isNot(same(pdfNumber)));
        expect(pdfNumberClone, equals(pdfNumber));
      });
      test('Test toString truncates double to int', () {
        const pdfNumber = PDFNumber(12.000000000002);
        expect(pdfNumber.toString(), equals('12'));
      });
      test('Test toString does not truncate double to int', () {
        const pdfNumber = PDFNumber(12.002);
        expect(pdfNumber.toString(), equals('12.002'));
        const pdfNumber2 = PDFNumber(12.0000000002);
        expect(pdfNumber2.toString(), equals('12.0000000002'));
      });
      test('Test toString truncates to int because of trailing zero', () {
        const pdfNumber = PDFNumber(12.00000000002);
        expect(pdfNumber.toString(), equals('12'));
      });
      test('Test toInt with int', () {
        const pdfNumber = PDFNumber(12);
        expect(pdfNumber.toInt(), equals(12));
      });
      test('Test toInt with double', () {
        const pdfNumber = PDFNumber(12.0);
        expect(pdfNumber.toInt(), equals(12));
      });
      test('Test toDouble with int', () {
        const pdfNumber = PDFNumber(12);
        expect(pdfNumber.toDouble(), equals(12.0));
      });
      test('Test toDouble with double', () {
        const pdfNumber = PDFNumber(12.2);
        expect(pdfNumber.toDouble(), equals(12.2));
      });
    });
    group('PDFLiteralString tests', () {
      test('Test codepoints match', () {
        final points = Uint8List.fromList(utf8.encode('Hello World'));
        final string = PDFLiteralString(points);
        expect(string.codePoints, equals(points));
      });
      test('Test toString uses asPDFString', () {
        final points = Uint8List.fromList(utf8.encode('Hello World'));
        final string = PDFLiteralString(points);
        expect(string.toString(), equals(string.asPDFString()));
        expect(string.toString(), '(Hello World)');
      });
      test('Test toString handles escapes', () {
        final points =
            Uint8List.fromList(utf8.encode('Hello World\n\t\r\b\f()\\'));
        final string = PDFLiteralString(points);
        expect(string.toString(), equals(string.asPDFString()));
        expect(string.toString(), '(Hello World\\n\\t\\r\\b\\f\\(\\)\\\\)');
      });
      test('Test equality', () {
        final string =
            PDFLiteralString(Uint8List.fromList(utf8.encode('Hello World')));
        final string2 =
            PDFLiteralString(Uint8List.fromList(utf8.encode('Hello World')));
        expect(string, equals(string2));
        expect(string.hashCode, string2.hashCode);
      });
      test('Test dart string utf8', () {
        final string =
            PDFLiteralString(Uint8List.fromList(utf8.encode('Hello World')));
        expect(string.asString(), equals('Hello World'));
      });
      test('Test dart string utf16', () {
        final string =
            PDFLiteralString(Uint8List.fromList(utf16.encode('Hello World')));
        expect(string.asString(), equals('Hello World'));
      });
      test('Test clone', () {
        final string =
            PDFLiteralString(Uint8List.fromList(utf16.encode('Hello World')));
        final clone = string.clone();
        expect(clone, string);
      });
    });
    group('PDFHexString tests', () {
      test('Test codepoints match', () {
        final points = Uint8List.fromList(utf8.encode('Hello World'));
        final string = PDFHexString(points);
        expect(string.codePoints, equals(points));
      });
      test('Test toString uses asPDFString', () {
        final points = Uint8List.fromList(utf8.encode('Hello World'));
        final string = PDFHexString(points);
        expect(string.toString(), equals(string.asPDFString()));
        expect(string.toString(), '<48656c6c6f20576f726c64>');
      });
      test('Test toString handles escapes', () {
        final points =
            Uint8List.fromList(utf8.encode('Hello World\n\t\r\b\f()\\'));
        final string = PDFHexString(points);
        expect(string.toString(), equals(string.asPDFString()));
        expect(string.toString(), '<48656c6c6f20576f726c640a090d080c28295c>');
      });
      test('Test equality', () {
        final string =
            PDFHexString(Uint8List.fromList(utf8.encode('Hello World')));
        final string2 =
            PDFHexString(Uint8List.fromList(utf8.encode('Hello World')));
        expect(string, equals(string2));
        expect(string.hashCode, string2.hashCode);
      });
      test('Test dart string utf8', () {
        final string =
            PDFHexString(Uint8List.fromList(utf8.encode('Hello World')));
        expect(string.asString(), equals('Hello World'));
      });
      test('Test dart string utf16', () {
        final string =
            PDFHexString(Uint8List.fromList(utf16.encode('Hello World')));
        expect(string.asString(), equals('Hello World'));
      });
      test('Test clone', () {
        final string =
            PDFHexString(Uint8List.fromList(utf16.encode('Hello World')));
        final clone = string.clone();
        expect(clone, string);
      });
    });
    group('PDFBoolean tests', () {
      test('Test value', () {
        const val = PDFBoolean(true);
        expect(val.value, isTrue);
        expect(const PDFBoolean(false).value, isFalse);
      });
      test('Test toString', () {
        expect(const PDFBoolean(true).toString(), 'true');
        expect(const PDFBoolean(false).toString(), 'false');
      });
      test('Test equality', () {
        expect(const PDFBoolean(true), const PDFBoolean(true));
        expect(const PDFBoolean(false) == const PDFBoolean(true), false);
        expect(
            const PDFBoolean(true).hashCode, const PDFBoolean(true).hashCode);
        expect(
            const PDFBoolean(false).hashCode == const PDFBoolean(true).hashCode,
            false);
      });
    });
    group('PDFNull tests', () {
      test('Test toString', () {
        expect(const PDFNull().toString(), 'null');
      });
      test('Test equality', () {
        expect(const PDFNull(), const PDFNull());
        expect(const PDFNull().hashCode, 0);
      });
    });
    group('PDFName tests', () {
      test('Test toString', () {
        expect(const PDFName('Test').toString(), '/Test');
      });
      test('Test value', () {
        expect(const PDFName('Test').value, 'Test');
      });
      test('Test equality', () {
        const name1 = '123';
        const name2 = '123';
        const name3 = '321';
        expect(const PDFName(name1), const PDFName(name2));
        expect(const PDFName(name1).hashCode, const PDFName(name2).hashCode);
        expect(const PDFName(name1).hashCode == const PDFName(name3).hashCode,
            false);
        expect(const PDFName(name1) == const PDFName(name3), false);
      });
    });
    group('PDFArray tests', () {
      test('Test length', () {
        expect(const PDFArray([PDFNull(), PDFNull()]).length, 2);
        expect(const PDFArray([]).length, 0);
      });
      test('Test toString', () {
        expect(
            const PDFArray([PDFNull(), PDFNull()]).toString(), '[null null]');
        expect(const PDFArray([PDFNull(), PDFNumber(123)]).toString(),
            '[null 123]');
        expect(const PDFArray([]).toString(), '[]');
      });
      test('Test write is not allowed', () {
        const arr = PDFArray([PDFNull(), PDFNull()]);
        expect(() => arr[0] = const PDFNumber(1), throwsArgumentError);
      });
      test('Test resize is not allowed', () {
        const arr = PDFArray([PDFNull(), PDFNull()]);
        expect(() => arr.length = 4, throwsArgumentError);
      });
      test('Test equality is deep', () {
        const val1 = PDFNumber(1);
        const val2 = PDFNumber(2);
        const val3 = PDFNumber(3);
        expect(const PDFArray([val1, val2]), const PDFArray([val1, val2]));
        expect(const PDFArray([val1, val2]) == const PDFArray([val1, val3]),
            false);
        expect(const PDFArray([val1, val2]).hashCode,
            const PDFArray([val1, val2]).hashCode);
        expect(
            const PDFArray([val1, val2]).hashCode ==
                const PDFArray([val1, val3]).hashCode,
            false);
      });
    });
    group('PDFDictionary tests', () {
      test('Test entries', () {
        expect(
            PDFDictionary({
              const PDFName('hello'): const PDFNumber(1),
              const PDFName('world'): const PDFBoolean(true),
            }).entries,
            {
              const PDFName('hello'): const PDFNumber(1),
              const PDFName('world'): const PDFBoolean(true),
            });
      });
      test('Test toString', () {
        expect(
            PDFDictionary({
              const PDFName('hello'): const PDFNumber(1),
              const PDFName('world'): const PDFBoolean(true),
            }).toString(),
            '<</hello 1 /world true>>');
      });
      test('Test index', () {
        final sut = PDFDictionary({
          const PDFName('hello'): const PDFNumber(1),
          const PDFName('world'): const PDFBoolean(true),
        });
        expect(sut[const PDFName('hello')], const PDFNumber(1));
        expect(sut[const PDFName('world')], const PDFBoolean(true));
      });
      test('Test has', () {
        final sut = PDFDictionary({
          const PDFName('hello'): const PDFNumber(1),
          const PDFName('world'): const PDFBoolean(true),
        });
        expect(sut.has(const PDFName('hello')), isTrue);
        expect(sut.has(const PDFName('world')), isTrue);
        expect(sut.has(const PDFName('test')), isFalse);
      });
    });
    group('PDFObjectReference tests', () {
      test('Test create reference', () {
        const ref = PDFObjectReference(objectId: 123);
        const ref2 = PDFObjectReference(objectId: 123, generationNumber: 1);
        expect(ref.objectId, 123);
        expect(ref.generationNumber, 0);
        expect(ref2.objectId, 123);
        expect(ref2.generationNumber, 1);
      });
      test('Test toString', () {
        const ref = PDFObjectReference(objectId: 123);
        const ref2 = PDFObjectReference(objectId: 123, generationNumber: 1);

        expect(ref.toString(), '123 0 R');
        expect(ref2.toString(), '123 1 R');
      });
      test('Test equality', () {
        const ref = PDFObjectReference(objectId: 123);
        const ref2 = PDFObjectReference(objectId: 123);
        const ref3 = PDFObjectReference(objectId: 123, generationNumber: 1);
        expect(ref, ref2);
        expect(ref == ref3, false);
        expect(ref.hashCode, ref2.hashCode);
        expect(ref.hashCode == ref3.hashCode, false);
      });
    });
    group('PDFCommand tests', () {
      test('Test command', () {
        expect(const PDFCommand('hello').command, 'hello');
      });
      test('Test toString', () {
        expect(const PDFCommand('hello').toString(), 'hello');
      });
      test('Test equality', () {
        expect(const PDFCommand('hello'), const PDFCommand('hello'));
        expect(const PDFCommand('hello') == const PDFCommand('world'), false);
        expect(const PDFCommand('hello').hashCode,
            const PDFCommand('hello').hashCode);
        expect(
            const PDFCommand('hello').hashCode ==
                const PDFCommand('world').hashCode,
            false);
      });
    });
    group('PDFStreamObject tests', () {
      test('Test create stream offset 0', () async {
        const dict = PDFDictionary({});
        final stream = PDFStreamObject(
          dictionary: dict,
          length: 5,
          offset: 0,
          isBinary: false,
          dataSource: ByteStream(Uint8List.fromList([1, 2, 3, 4, 5])),
        );
        expect(stream.dictionary, const PDFDictionary({}));
        expect(await stream.readRaw(), [1, 2, 3, 4, 5]);
      });
      test('Test create stream offset 0', () async {
        const dict = PDFDictionary({});
        final stream = PDFStreamObject(
          dictionary: dict,
          length: 4,
          offset: 1,
          isBinary: false,
          dataSource: ByteStream(Uint8List.fromList([1, 2, 3, 4, 5])),
        );
        expect(stream.dictionary, const PDFDictionary({}));
        expect(await stream.readRaw(), [2, 3, 4, 5]);
      });
      test('Test read without filters', () async {
        const dict = PDFDictionary({});
        final stream = PDFStreamObject(
          dictionary: dict,
          length: 5,
          offset: 0,
          isBinary: false,
          dataSource: ByteStream(Uint8List.fromList([1, 2, 3, 4, 5])),
        );
        expect(stream.dictionary, const PDFDictionary({}));

        final mockResolver = MockObjectResolver();
        when(() => mockResolver.resolve(any())).thenAnswer((_) async => null);

        expect(await stream.read(mockResolver), [1, 2, 3, 4, 5]);
      });
      test('Test read with single filter', () async {
        const dict = PDFDictionary({});
        final bytes = File('test/resources/ASCIIHex.bin').readAsBytesSync();
        final stream = PDFStreamObject(
          dictionary: dict,
          length: bytes.length,
          offset: 0,
          isBinary: false,
          dataSource: ByteStream(bytes),
        );
        expect(stream.dictionary, const PDFDictionary({}));

        final mockResolver = MockObjectResolver();
        when(() => mockResolver.resolve(any()))
            .thenAnswer((_) async => const PDFName('ASCIIHexDecode'));

        expect(utf8.decode(await stream.read(mockResolver)),
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec ac malesuada tellus. Quisque a arcu semper, tristique nibh eu, convallis lacus. Donec neque justo, condimentum sed molestie ac, mollis eu nibh. Vivamus pellentesque condimentum fringilla. Nullam euismod ac risus a semper. Etiam hendrerit scelerisque sapien tristique varius.');
      });
      test('Test read with bad filter', () async {
        const dict = PDFDictionary({});
        final bytes = File('test/resources/ASCIIHex.bin').readAsBytesSync();
        final stream = PDFStreamObject(
          dictionary: dict,
          length: bytes.length,
          offset: 0,
          isBinary: false,
          dataSource: ByteStream(bytes),
        );
        expect(stream.dictionary, const PDFDictionary({}));

        final mockResolver = MockObjectResolver();
        when(() => mockResolver.resolve(any()))
            .thenAnswer((_) async => const PDFNumber(1));

        expect(() => stream.read(mockResolver), throwsA(isA<ParseException>()));
      });
      test('Test read with array filter', () async {
        const dict = PDFDictionary({});
        final bytes = File('test/resources/ASCIIHex.bin').readAsBytesSync();
        final stream = PDFStreamObject(
          dictionary: dict,
          length: bytes.length,
          offset: 0,
          isBinary: false,
          dataSource: ByteStream(bytes),
        );
        expect(stream.dictionary, const PDFDictionary({}));

        final mockResolver = MockObjectResolver();
        when(() => mockResolver.resolve(any())).thenAnswer(
            (_) async => const PDFArray([PDFName('ASCIIHexDecode')]));

        expect(utf8.decode(await stream.read(mockResolver)),
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec ac malesuada tellus. Quisque a arcu semper, tristique nibh eu, convallis lacus. Donec neque justo, condimentum sed molestie ac, mollis eu nibh. Vivamus pellentesque condimentum fringilla. Nullam euismod ac risus a semper. Etiam hendrerit scelerisque sapien tristique varius.');
      });
      test('Test equality', () {
        const dict = PDFDictionary({});
        final source = ByteStream(Uint8List.fromList([1, 2, 3, 4, 5]));
        final stream = PDFStreamObject(
          dictionary: dict,
          length: 5,
          offset: 0,
          isBinary: false,
          dataSource: source,
        );
        final stream2 = PDFStreamObject(
          dictionary: dict,
          length: 5,
          offset: 0,
          isBinary: false,
          dataSource: source,
        );
        final stream3 = PDFStreamObject(
          dictionary: dict,
          length: 4,
          offset: 1,
          isBinary: false,
          dataSource: source,
        );
        expect(stream, stream2);
        expect(stream == stream3, false);
        expect(stream.hashCode, stream2.hashCode);
        expect(stream.hashCode == stream3.hashCode, false);
      });
    });
    group('PDFIndirectObject tests', () {
      test('Test equality', () {
        // ignore: prefer_const_constructors
        final val1 = PDFIndirectObject(
          objectId: 123,
          generationNumber: 0,
          // ignore: prefer_const_constructors
          object: PDFNull(),
        );
        // ignore: prefer_const_constructors
        final val2 = PDFIndirectObject(
          objectId: 123,
          generationNumber: 0,
          // ignore: prefer_const_constructors
          object: PDFNull(),
        );
        // ignore: prefer_const_constructors
        final val3 = PDFIndirectObject(
          objectId: 123,
          generationNumber: 1,
          // ignore: prefer_const_constructors
          object: PDFNumber(12),
        );
        expect(val1, val2);
        expect(val1.hashCode, val2.hashCode);
        expect(val1 == val3, false);
        expect(val1.hashCode == val3.hashCode, false);
      });
    });
  });
}

class MockObjectResolver extends Mock implements ObjectResolver {}
