// Stub implementation for web platform
import 'dart:async';

class Directory {
  final String path;
  Directory(this.path);
}

Future<Directory> getApplicationDocumentsDirectory() async {
  throw UnsupportedError('getApplicationDocumentsDirectory is not supported on Web');
}

Future<Directory?> getDownloadsDirectory() async {
  throw UnsupportedError('getDownloadsDirectory is not supported on Web');
}

Future<Directory?> getExternalStorageDirectory() async {
  throw UnsupportedError('getExternalStorageDirectory is not supported on Web');
}
