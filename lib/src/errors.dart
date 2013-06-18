part of distributed_dart;

class UnsupportedOperationError implements Error {
  final message;

  /** The [message] describes the erroneous argument. */
  UnsupportedOperationError([this.message]);

  String toString() {
    if (message != null) {
      return "Not supported operation: $message";
    }
    return "Not supported operation";
  }
}
