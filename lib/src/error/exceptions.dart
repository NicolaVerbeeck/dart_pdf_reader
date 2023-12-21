/// A class of exceptions thrown when an unexpected end of file is reached
class EOFException implements Exception {
  const EOFException();

  // coverage:ignore-start
  @override
  String toString() => 'EOFException';
  // coverage:ignore-end
}

/// A class of exceptions thrown when an unexpected parse error is encountered
class ParseException implements Exception {
  final String _message;

  const ParseException(this._message);

  // coverage:ignore-start
  @override
  String toString() => 'ParseException: $_message';
  // coverage:ignore-end
}

class ActionTypeNotSupported implements Exception {
  final String _message;

  const ActionTypeNotSupported(this._message);

  // coverage:ignore-start
  @override
  String toString() => 'ActionTypeNotSupported: $_message';
  // coverage:ignore-end
}
