import 'package:dart_pdf_reader/dart_pdf_reader.dart';
import 'package:meta/meta.dart';

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

/// Type of a PDF outline action creator function
typedef PDFOutlineCreator = PDFOutlineAction? Function(
  PDFOutlineActionType,
  PDFDictionary,
);

/// A PDF outline action
abstract class PDFOutlineAction {
  static final _outlineCreators = <PDFOutlineActionType, PDFOutlineCreator>{};

  /// Register custom outline [creator] for a specific action [type]. This
  /// allows to extend the library with custom outline actions, or overwrite
  /// existing ones. Creators registered here take precedence over the default
  /// ones.
  static void registerOutlineCreator(
    PDFOutlineActionType type,
    PDFOutlineCreator creator,
  ) {
    _outlineCreators[type] = creator;
  }

  const PDFOutlineAction();

  /// The type of the action
  PDFOutlineActionType get type;

  factory PDFOutlineAction.fromDictionary(
    PDFDictionary dictionary,
  ) {
    final typeName =
        (dictionary[const PDFName('S')] as PDFName).value.toLowerCase();
    final PDFOutlineActionType type;
    try {
      type = PDFOutlineActionType.values.byName(typeName);
    } catch (e) {
      throw ActionTypeNotSupported('Unknown action type: $typeName');
    }
    final res = _outlineCreators[type]?.call(type, dictionary);
    if (res != null) return res;

    switch (type) {
      case PDFOutlineActionType.goto:
        return PDFOutlineGoToAction(
          destination: (dictionary[const PDFName('D')] as PDFArray).first
              as PDFObjectReference,
        );
      default:
        throw ActionTypeNotSupported('Unhandled outline action type: $type');
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
