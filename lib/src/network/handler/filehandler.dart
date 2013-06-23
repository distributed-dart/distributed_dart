part of distributed_dart;

const String _NETWORK_FILE_HANDLER = "file"; 

_fileHandler(dynamic request, NodeAddress senderAddress) {
  if (request is Map) {
    request.forEach((String hash, List<int> fileContent) {
      _DartCodeDb._downloadQueue[hash].completer.complete(fileContent);
    });
  } else {
    String s = "Not supported input object for _fileHandler.";
    throw new UnsupportedOperationError(s);
  }
}
