import 'dart:math';

import 'package:dart_pdf_reader/src/model/pdf_document.dart';
import 'package:dart_pdf_reader/src/model/pdf_page.dart';
import 'package:dart_pdf_reader/src/model/pdf_types.dart';
import 'package:dart_pdf_reader/src/parser/object_resolver.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockPDFDocument extends Mock implements PDFDocument {}

class _MockObjectResolver extends Mock implements ObjectResolver {}

class _MockPDFPageNode extends Mock implements PDFPageNode {}

class _MockStream extends Mock implements PDFStreamObject {}

void main() {
  group('PDFPageNode tests', () {
    test('Test get or inherited gets self first', () {
      final parent = _MockPDFPageNode();
      final resolver = _MockObjectResolver();

      when(() => parent.getOrInherited<PDFArray>(const PDFName('MediaBox')))
          .thenAnswer((_) => const PDFArray([
                PDFNumber(0),
                PDFNumber(10),
                PDFNumber(120),
                PDFNumber(2000),
              ]));

      final sut = PDFPageObjectNode(
        _MockPDFDocument(),
        parent,
        resolver,
        PDFDictionary({
          const PDFName('MediaBox'): const PDFArray([
            PDFNumber(0),
            PDFNumber(0),
            PDFNumber(20),
            PDFNumber(30),
          ]),
        }),
      );

      final rect = sut.mediaBox;
      expect(rect, const Rectangle(0.0, 0.0, 20.0, 30.0));
      verifyNever(
          () => parent.getOrInherited<PDFArray>(const PDFName('MediaBox')));
    });

    test('Test gets from parent', () {
      final parent = _MockPDFPageNode();
      final resolver = _MockObjectResolver();

      when(() => parent.getOrInherited<PDFArray>(const PDFName('MediaBox')))
          .thenAnswer((_) => const PDFArray([
                PDFNumber(0),
                PDFNumber(10),
                PDFNumber(120),
                PDFNumber(2000),
              ]));

      final sut = PDFPageObjectNode(
        _MockPDFDocument(),
        parent,
        resolver,
        const PDFDictionary({}),
      );

      final rect = sut.mediaBox;
      expect(rect, const Rectangle(0.0, 10.0, 120.0, 1990.0));
    });

    test('Test get dictionary', () {
      final sut = PDFPageObjectNode(
        _MockPDFDocument(),
        null,
        _MockObjectResolver(),
        PDFDictionary({
          const PDFName('MediaBox'): const PDFArray([
            PDFNumber(0),
            PDFNumber(10),
            PDFNumber(120),
            PDFNumber(2000),
          ]),
        }),
      );
      expect(
          sut.dictionary,
          PDFDictionary({
            const PDFName('MediaBox'): const PDFArray([
              PDFNumber(0),
              PDFNumber(10),
              PDFNumber(120),
              PDFNumber(2000),
            ]),
          }));
    });
    test('Test get contents tries to resolve', () async {
      final parent = _MockPDFPageNode();
      final resolver = _MockObjectResolver();

      when(() => resolver.resolve(const PDFNumber(1337)))
          .thenAnswer((invocation) async => null);

      final sut = PDFPageObjectNode(
        _MockPDFDocument(),
        parent,
        resolver,
        PDFDictionary({
          const PDFName('Contents'): const PDFNumber(1337),
        }),
      );

      expect(await sut.contentStreams, null);
      verify(() => resolver.resolve(const PDFNumber(1337))).called(1);
    });
    test('Test get contents does not resolve to parent', () async {
      final parent = _MockPDFPageNode();
      final resolver = _MockObjectResolver();

      when(() => parent.getOrInherited(const PDFName('Contents')))
          .thenAnswer((_) => const PDFNull());
      when(() => resolver.resolve(null)).thenAnswer((_) async => null);

      final sut = PDFPageObjectNode(
        _MockPDFDocument(),
        parent,
        resolver,
        const PDFDictionary({}),
      );

      expect(await sut.contentStreams, null);
      verifyNever(() => parent.getOrInherited(const PDFName('Contents')));
    });
    test('Test supports single content stream', () async {
      final parent = _MockPDFPageNode();
      final resolver = _MockObjectResolver();
      final stream1 = _MockStream();

      when(() => resolver.resolve(const PDFNumber(1337)))
          .thenAnswer((_) async => stream1);

      final sut = PDFPageObjectNode(
        _MockPDFDocument(),
        parent,
        resolver,
        PDFDictionary({
          const PDFName('Contents'): const PDFNumber(1337),
        }),
      );

      expect(await sut.contentStreams, [stream1]);
      // ignore: deprecated_member_use_from_same_package
      expect(await sut.contentStream, stream1);
    });
    test('Test supports multiple content streams', () async {
      final parent = _MockPDFPageNode();
      final resolver = _MockObjectResolver();
      final stream1 = _MockStream();
      final stream2 = _MockStream();

      when(() => resolver.resolve<PDFStreamObject>(
              const PDFObjectReference(objectId: 11, generationNumber: 0)))
          .thenAnswer((_) async => stream2);
      when(() => resolver.resolve<PDFStreamObject>(stream1))
          .thenAnswer((_) async => stream1);
      when(() => resolver.resolve(const PDFNumber(1337))).thenAnswer(
          (_) async => PDFArray([
                stream1,
                const PDFObjectReference(objectId: 11, generationNumber: 0)
              ]));

      final sut = PDFPageObjectNode(
        _MockPDFDocument(),
        parent,
        resolver,
        PDFDictionary({
          const PDFName('Contents'): const PDFNumber(1337),
        }),
      );

      expect(await sut.contentStreams, [stream1, stream2]);
    });
    test('Test contentStream returns first stream when multiple are defined',
        () async {
      final parent = _MockPDFPageNode();
      final resolver = _MockObjectResolver();
      final stream1 = _MockStream();
      final stream2 = _MockStream();

      when(() => resolver.resolve<PDFStreamObject>(
              const PDFObjectReference(objectId: 11, generationNumber: 0)))
          .thenAnswer((_) async => stream2);
      when(() => resolver.resolve<PDFStreamObject>(stream1))
          .thenAnswer((_) async => stream1);
      when(() => resolver.resolve(const PDFNumber(1337))).thenAnswer(
          (_) async => PDFArray([
                stream1,
                const PDFObjectReference(objectId: 11, generationNumber: 0)
              ]));

      final sut = PDFPageObjectNode(
        _MockPDFDocument(),
        parent,
        resolver,
        PDFDictionary({
          const PDFName('Contents'): const PDFNumber(1337),
        }),
      );

      // ignore: deprecated_member_use_from_same_package
      expect(await sut.contentStream, stream1);
    });
    test('Test get resources tries to resolve', () async {
      final parent = _MockPDFPageNode();
      final resolver = _MockObjectResolver();

      when(() => resolver.resolve<PDFDictionary>(const PDFNumber(1337)))
          .thenAnswer((invocation) async => null);

      final sut = PDFPageObjectNode(
        _MockPDFDocument(),
        parent,
        resolver,
        PDFDictionary({
          const PDFName('Resources'): const PDFNumber(1337),
        }),
      );

      expect(await sut.resources, null);
      verify(() => resolver.resolve<PDFDictionary>(const PDFNumber(1337)))
          .called(1);
    });
  });
}
