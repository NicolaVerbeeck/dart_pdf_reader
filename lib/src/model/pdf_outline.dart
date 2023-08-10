import 'package:meta/meta.dart';
import 'package:dart_pdf_reader/dart_pdf_reader.dart';

enum PDFOutlineActionType {
  goto,
  gotor,
  gotoe,
  launch,
  thread,
  uri,
  sound,
  movie,
  hide,
  named,
  submitform,
  resetform,
  importdata,
  javascript,
  setocgstate,
  rendition,
  trans,
  goto3dview,
}

/// A PDF outline item
@immutable
class PDFOutlineItem {
  /// The title of the outline
  final String title;

  // The action of the outline
  final PDFOutlineAction action;

  /// Creates a new [PDFOutlineItem] object.
  const PDFOutlineItem({
    required this.title,
    required this.action,
  });

  @override
  String toString() {
    return 'PDFOutlineItem{title: $title, action: $action}';
  }
}

/// A PDF outline action
abstract class PDFOutlineAction {
  const PDFOutlineAction();

  /// The type of the action
  PDFOutlineActionType get type;

  factory PDFOutlineAction.fromDictionary(
    PDFDictionary dictionary,
  ) {
    final type = PDFOutlineActionType.values.byName(
        (dictionary[const PDFName('S')] as PDFName).value.toLowerCase());
    switch (type) {
      case PDFOutlineActionType.goto:
        return PDFOutlineGoToAction(
          destination: (dictionary[const PDFName('D')] as PDFArray).first
              as PDFObjectReference,
        );
      default:
        throw Exception('Unknown outline action type: $type');
    }
  }

  @override
  String toString() {
    return 'PDFOutlineAction{type: $type}';
  }
}

/// A PDF outline GoTo Action
@immutable
class PDFOutlineGoToAction extends PDFOutlineAction {
  final PDFObjectReference destination;

  /// Creates a new [PDFOutlineGoToAction] object.
  const PDFOutlineGoToAction({
    required this.destination,
  });

  @override
  PDFOutlineActionType get type => PDFOutlineActionType.goto;

  @override
  String toString() {
    return 'PDFOutlineGoToAction{title: $type, destination: $destination}';
  }
}
