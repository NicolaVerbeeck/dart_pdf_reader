import 'dart:typed_data';

extension ListHelpers on List<int> {
  Uint8List asUint8List() {
    if (this is Uint8List) return this as Uint8List;
    return Uint8List.fromList(this);
  }
}
