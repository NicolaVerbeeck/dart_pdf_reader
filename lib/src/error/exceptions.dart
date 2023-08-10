import 'dart:io';

/// A class of exceptions thrown when an unexpected end of file is reached
class EOFException extends IOException {
  EOFException();

  @override
  String toString() => 'EOFException';
}

/// A class of exceptions thrown when an unexpected parse error is encountered
class ParseException extends IOException {
  final String _message;

  ParseException(this._message);

  @override
  String toString() => 'ParseException: $_message';
}

class ActionTypeNotSupported implements Exception {
  final String _message;

  ActionTypeNotSupported(this._message);

  @override
  String toString() => 'ActionTypeNotSupported: $_message';
}
