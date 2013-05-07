part of distributed_dart;

class InvalidWorkDirException implements Exception {
  /**
   * A message describing the error.
   */
  final String message;

  /**
   * Creates a new FileChangedException with an optional error [message].
   */
  const InvalidWorkDirException([this.message = ""]);

  String toString() => "InvalidWorkDirException: $message";
}

class WorkDirInUseException implements Exception {
  /**
   * A message describing the error.
   */
  final String message;

  /**
   * Creates a new FileChangedException with an optional error [message].
   */
  const WorkDirInUseException([this.message = ""]);

  String toString() => "InvalidWorkDirException: $message";
}

class FileChangedException implements Exception {
  /**
   * A message describing the error.
   */
  final String message;

  /**
   * Creates a new FileChangedException with an optional error [message].
   */
  const FileChangedException([this.message = ""]);

  String toString() => "FileChangedException: $message";
}

class ScannerException implements Exception {
  /**
   * A message describing the error.
   */
  final String message;

  /**
   * Creates a new ScannerException with an optional error [message].
   */
  const ScannerException([this.message = ""]);

  String toString() => "ScannerException: $message";
}