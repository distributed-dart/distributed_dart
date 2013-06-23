part of distributed_dart;

class DownloadRequest {
  final Completer<List<int>> completer;
  Future future;
  
  DownloadRequest(Path destination) : completer = new Completer() {
    this.future = completer.future.then((List<int> fileContent) {
      return new File.fromPath(destination).writeAsBytes(fileContent);
    });
  }
}
