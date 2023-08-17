import 'package:dart_pdf_reader/dart_pdf_reader.dart';
import 'package:dart_pdf_reader/src/model/pdf_outline.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockedPDFOutlineAction extends Mock implements PDFOutlineAction {}

void main() {
  group('PDFOutline tests', () {
    setUp(() {
      clearOutlineCreators();
    });
    test('Test default goto creator', () {
      final action = PDFOutlineAction.fromDictionary(PDFDictionary({
        const PDFName('S'): const PDFName('GoTo'),
        const PDFName('D'): const PDFArray([
          PDFObjectReference(objectId: 133, generationNumber: 3),
        ]),
      }));

      expect(action, isA<PDFOutlineGoToAction>());
      expect(action.type, PDFOutlineActionType.goto);
      action as PDFOutlineGoToAction;
      final destinationArray = action.destination as PDFArray;
      final destItem = destinationArray[0] as PDFObjectReference;
      expect(destItem.objectId, 133);
      expect(destItem.generationNumber, 3);
    });
    test('Test unknown action type', () {
      expect(
          () => PDFOutlineAction.fromDictionary(PDFDictionary({
                const PDFName('S'): const PDFName('invalid'),
              })),
          throwsA(isA<ActionTypeNotSupported>()));
    });
    test('Test default creator unhandled', () {
      expect(
          () => PDFOutlineAction.fromDictionary(PDFDictionary({
                const PDFName('S'): const PDFName('goto3dview'),
              })),
          throwsA(isA<ActionTypeNotSupported>()));
    });
    test('Test override goto creator', () {
      PDFOutlineAction.registerOutlineCreator(
          PDFOutlineActionType.goto, (_, dict) => _MockedPDFOutlineAction());
      final action = PDFOutlineAction.fromDictionary(PDFDictionary({
        const PDFName('S'): const PDFName('GoTo'),
        const PDFName('D'): const PDFArray([
          PDFObjectReference(objectId: 133, generationNumber: 3),
        ]),
      }));

      expect(action, isA<_MockedPDFOutlineAction>());
    });
  });
}
