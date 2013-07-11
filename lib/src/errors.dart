part of distributed_dart;

class UnsupportedOperationError extends Error {
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

class JsonCyclicError extends Error {
  final String message;
  const JsonCyclicError([this.message = ""]);
  String toString() => "Cyclic error!: $message";
}
