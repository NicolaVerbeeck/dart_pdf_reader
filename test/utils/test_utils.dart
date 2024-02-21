import 'dart:io';

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
