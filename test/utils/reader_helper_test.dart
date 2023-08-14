import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_pdf_reader/src/error/exceptions.dart';
import 'package:dart_pdf_reader/src/parser/token_stream.dart';
import 'package:dart_pdf_reader/src/utils/byte_stream.dart';
import 'package:dart_pdf_reader/src/utils/reader_helper.dart';
import 'package:test/test.dart';

void main() {
  group('Reader helper tests', () {
    group('Test read line skip empty', () {
      test('Test normal', () async {
        final stream =
            ByteStream(Uint8List.fromList(utf8.encode('\r\n456\n567')));
        expect(await ReaderHelper.readLineSkipEmpty(stream), '456');
        expect(await ReaderHelper.readLineSkipEmpty(stream), '567');
      });
      test('Test with comments', () async {
        final stream =
            ByteStream(Uint8List.fromList(utf8.encode('\r\n%456\n567')));
        expect(await ReaderHelper.readLineSkipEmpty(stream), '567');
      });
      test('EOF is null', () async {
        final stream = ByteStream(Uint8List.fromList(utf8.encode('')));
        expect(await ReaderHelper.readLineSkipEmpty(stream), null);
      });
      test('No lines is null', () async {
        final stream =
            ByteStream(Uint8List.fromList(utf8.encode('\r\n%456\n')));
        expect(await ReaderHelper.readLineSkipEmpty(stream), null);
      });
    });
    group('Test read line', () {
      test('Test read line eof returns null', () async {
        final stream = ByteStream(Uint8List.fromList(utf8.encode('')));
        expect(await ReaderHelper.readLine(stream), null);
      });
      test('Test read line returns line', () async {
        final stream = ByteStream(Uint8List.fromList(utf8.encode('123\n%456')));
        expect(await ReaderHelper.readLine(stream), '123');
        expect(await ReaderHelper.readLine(stream), '%456');
      });
    });
    group('From hex', () {
      test('Test bytes from hex', () {
        expect(
            ReaderHelper.fromHex(
                '155232F3CBDAD886B34F28BDAFCC9A47240F977B0E9B'),
            [
              21,
              82,
              50,
              243,
              203,
              218,
              216,
              134,
              179,
              79,
              40,
              189,
              175,
              204,
              154,
              71,
              36,
              15,
              151,
              123,
              14,
              155
            ]);
      });
    });
    group('Remove comments', () {
      test('Remove comments end of line', () {
        expect(ReaderHelper.removeComments('Hello %world'), 'Hello ');
      });
      test('Remove comments beginning of line', () {
        expect(ReaderHelper.removeComments('%Hello world'), '');
      });
      test('Does not remove %%EOF', () {
        expect(ReaderHelper.removeComments('%%EOF'), '%%EOF');
      });
      test('Does not remove %PDF-1.7', () {
        expect(ReaderHelper.removeComments('%PDF-1.7'), '%PDF-1.7');
      });
      test('Does remove %%EOF if not first', () {
        expect(ReaderHelper.removeComments('Hello %%EOF'), 'Hello ');
      });
      test('Does remove %PDF-1.7 if not first', () {
        expect(ReaderHelper.removeComments('Hello %PDF-1.7'), 'Hello ');
      });
    });
    group('Skip until', () {
      test('It skips until the byte is found', () async {
        final stream = ByteStream(Uint8List.fromList(utf8.encode('456\n567')));
        await ReaderHelper.skipUntilFirst(stream, 0x36);
        expect(await stream.position, 2);
        expect(await stream.readByte(), 0x36);
      });
      test('Throws if the byte can not be found', () async {
        final stream = ByteStream(Uint8List.fromList(utf8.encode('456\n567')));
        expect(ReaderHelper.skipUntilFirst(stream, 0x71),
            throwsA(isA<EOFException>()));
      });
      test('Skips bytes found in comments', () async {
        final stream = ByteStream(Uint8List.fromList(utf8.encode('%456\n567')));
        await ReaderHelper.skipUntilFirst(stream, 0x36);
        expect(await stream.position, 6);
        expect(await stream.readByte(), 0x36);
      });
    });
    group('Skip object header', () {
      test('It skips the object header', () async {
        final stream =
            ByteStream(Uint8List.fromList(utf8.encode('456 567 obj<<')));
        final tokenStream = TokenStream(stream);
        await ReaderHelper.skipObjectHeader(tokenStream);
        expect(await stream.position, 11);
        expect(await stream.readByte(), 0x3c);
      });
      test('It skips the object header', () async {
        final stream = ByteStream(
            Uint8List.fromList(utf8.encode('456 567 obj %hello\n<<')));
        final tokenStream = TokenStream(stream);
        await ReaderHelper.skipObjectHeader(tokenStream);
        expect(await stream.position, 19);
        expect(await stream.readByte(), 0x3c);
      });
      test('It skips the object header', () async {
        final stream =
            ByteStream(Uint8List.fromList(utf8.encode('456 567 obj\n[')));
        final tokenStream = TokenStream(stream);
        await ReaderHelper.skipObjectHeader(tokenStream);
        expect(await stream.position, 12);
        expect(await stream.readByte(), 0x5B);
      });
      test('It throws if the object header is not found', () async {
        final stream =
            ByteStream(Uint8List.fromList(utf8.encode('456 567 ob')));
        final tokenStream = TokenStream(stream);
        expect(ReaderHelper.skipObjectHeader(tokenStream),
            throwsA(isA<EOFException>()));
      });
      test('It throws if the object header is the last part of the stream',
          () async {
        final stream =
            ByteStream(Uint8List.fromList(utf8.encode('456 567 obj')));
        final tokenStream = TokenStream(stream);
        expect(ReaderHelper.skipObjectHeader(tokenStream),
            throwsA(isA<EOFException>()));
      });
    });
    group('Test skip until first non-whitespace', () {
      test('Skips spaces until first non whitespace is encountered', () async {
        final stream = ByteStream(Uint8List.fromList(utf8.encode(' 4')));
        final tokenStream = TokenStream(stream);
        await ReaderHelper.skipUntilFirstNonWhitespace(tokenStream);
        expect(await stream.position, 1);
      });
      test('Skips newlines until first non whitespace is encountered',
          () async {
        final stream = ByteStream(Uint8List.fromList(utf8.encode('\n\n\n4')));
        final tokenStream = TokenStream(stream);
        await ReaderHelper.skipUntilFirstNonWhitespace(tokenStream);
        expect(await stream.position, 3);
      });
      test('Skips carriage returns until first non whitespace is encountered',
          () async {
        final stream = ByteStream(Uint8List.fromList(utf8.encode('\r\r\r4')));
        final tokenStream = TokenStream(stream);
        await ReaderHelper.skipUntilFirstNonWhitespace(tokenStream);
        expect(await stream.position, 3);
      });
      test('Skips tabs until first non whitespace is encountered', () async {
        final stream = ByteStream(Uint8List.fromList(utf8.encode('\t\t\t4')));
        final tokenStream = TokenStream(stream);
        await ReaderHelper.skipUntilFirstNonWhitespace(tokenStream);
        expect(await stream.position, 3);
      });
      test('Skips comments until first non whitespace is encountered',
          () async {
        final stream = ByteStream(Uint8List.fromList(utf8.encode(' %\n4')));
        final tokenStream = TokenStream(stream);
        await ReaderHelper.skipUntilFirstNonWhitespace(tokenStream);
        expect(await stream.position, 3);
      });
      test('Throws if no non-whitespace character is found', () async {
        final stream = ByteStream(Uint8List.fromList(utf8.encode(' ')));
        final tokenStream = TokenStream(stream);
        expect(ReaderHelper.skipUntilFirstNonWhitespace(tokenStream),
            throwsA(isA<EOFException>()));
      });
    });
  });
}
