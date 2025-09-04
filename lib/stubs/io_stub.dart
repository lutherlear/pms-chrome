// Stub implementation for web platform

class File {
  final String path;
  File(this.path);
  
  Future<bool> exists() async => false;
  Future<File> copy(String newPath) async => File(newPath);
  Future<void> delete() async {}
}

class Directory {
  final String path;
  Directory(this.path);
  
  Future<bool> exists() async => false;
  Future<Directory> create({bool recursive = false}) async => this;
}

class Platform {
  static bool get isWindows => false;
  static bool get isLinux => false;
  static bool get isMacOS => false;
  static bool get isAndroid => false;
  static bool get isIOS => false;
}
