part of distributed_dart;

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