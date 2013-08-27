part of distributed_dart;

class _DownloadRequest {
  final Completer<List<int>> completer;
  Future future;
  
  _DownloadRequest(String destinationPath) : completer = new Completer() {
    this.future = completer.future.then((List<int> fileContent) {
      return new File(destinationPath).writeAsBytes(fileContent);
    });
  }
}
