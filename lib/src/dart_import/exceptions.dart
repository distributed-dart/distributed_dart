part of distributed_dart;

class InvalidWorkDirException implements Exception {
  final String message;
  const InvalidWorkDirException([this.message = ""]);
  String toString() => "InvalidWorkDirException: $message";
}

class WorkDirInUseException implements Exception {
  final String message;
  const WorkDirInUseException([this.message = ""]);
  String toString() => "InvalidWorkDirException: $message";
}

class FileChangedException implements Exception {
  final String message;
  const FileChangedException([this.message = ""]);
  String toString() => "FileChangedException: $message";
}

class ScannerException implements Exception {
  final String message;
  const ScannerException([this.message = ""]);
  String toString() => "ScannerException: $message";
}
