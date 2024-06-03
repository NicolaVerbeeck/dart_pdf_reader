import '../../dart_pdf_reader.dart';
import 'package:meta/meta.dart';

/// Action types for pdf outlines
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

  /// The action of the outline
  final PDFOutlineAction action;

  /// Creates a new [PDFOutlineItem] object.
  const PDFOutlineItem({
    required this.title,
    required this.action,
  });

  // coverage:ignore-start
  @override
  String toString() {
    return 'PDFOutlineItem{title: $title, action: $action}';
  }
// coverage:ignore-end
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

  /// Creates a new outline action from the given [dictionary]. If any custom
  /// creator for the type is registered, it will be first queried to produce
  /// the action. If it returns `null`, the default creator will be used.
  ///
  /// If the type is not known or no creator could create a [PDFOutlineAction]
  /// for it, an [ActionTypeNotSupported] exception is thrown.
  factory PDFOutlineAction.fromDictionary(
    PDFDictionary dictionary,
  ) {
    final typeName = (dictionary[PDFNames.s] as PDFName).value.toLowerCase();
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
          destination: dictionary[PDFNames.d]!,
        );
      default:
        throw ActionTypeNotSupported('Unhandled outline action type: $type');
    }
  }

  // coverage:ignore-start
  @override
  String toString() {
    return 'PDFOutlineAction{type: $type}';
  }
// coverage:ignore-end
}

/// A PDF outline GoTo Action
@immutable
class PDFOutlineGoToAction extends PDFOutlineAction {
  /// The destination of the action. Can be a [PDFStringLike], [PDFArray]
  /// or a [PDFName]. See PDF 1.7 specification section 8.2.1 for more
  final PDFObject destination;

  /// Creates a new [PDFOutlineGoToAction] object.
  const PDFOutlineGoToAction({
    required this.destination,
  });

  @override
  PDFOutlineActionType get type => PDFOutlineActionType.goto;

  // coverage:ignore-start
  @override
  String toString() {
    return 'PDFOutlineGoToAction{title: $type, destination: $destination}';
  }
// coverage:ignore-end
}

@visibleForTesting
void clearOutlineCreators() {
  PDFOutlineAction._outlineCreators.clear();
}
