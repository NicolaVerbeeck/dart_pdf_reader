import 'dart:io';
import 'dart:typed_data';

Future<File> createTempFile({required String suffix}) {
  final path = Directory.systemTemp.absolute.path;
  while (true) {
    final filename = '$path/${DateTime.now().millisecondsSinceEpoch}$suffix';
    final file = File(filename);
    if (!file.existsSync()) {
      return file.create();
    }
  }
}

bool isJpeg(Uint8List bytes) {
  return bytes.length > 2 && bytes[0] == 0xFF && bytes[1] == 0xD8;
}

bool isPng(Uint8List bytes) {
  return bytes.length > 8 && bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47 && bytes[4] == 0x0D && bytes[5] == 0x0A && bytes[6] == 0x1A && bytes[7] == 0x0A;
}
