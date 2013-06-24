part of distributed_dart;

class _DownloadRequest {
  final Completer<List<int>> completer;
  Future future;
  
  _DownloadRequest(Path destination) : completer = new Completer() {
    this.future = completer.future.then((List<int> fileContent) {
      return new File.fromPath(destination).writeAsBytes(fileContent);
    });
  }
}
