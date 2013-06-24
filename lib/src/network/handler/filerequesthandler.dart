part of distributed_dart;

const String _NETWORK_FILE_REQUEST_HANDLER = "file_request"; 

_fileRequestHandler (dynamic request, NodeAddress senderAddress) {
  if (request is List) {
    Map<String,List<int>> requestedFiles = new Map();
    
    Future.wait(request.map((String hash) {
      return _DartCodeDb.getSourceFromHash(hash).then((List<int> fileContent) {
        requestedFiles[hash] = fileContent;
      });
    })).then((_) {
      new _Network(senderAddress).send(_NETWORK_FILE_HANDLER, requestedFiles);
    });
  } else {
    String s = "Not supported input object for _fileRequestHandler.";
    throw new UnsupportedOperationError(s);
  }
}
