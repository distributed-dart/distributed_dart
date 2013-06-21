part of distributed_dart;

/**
 * Is only used to easier to collect a list of files there are needed to be 
 * downloaded from another computer. The file to be downloaded is represented 
 * by the [hash] value and when the file is downloaded it should be saved as 
 * [hashFilePath]. At last there should be created a link between [hashFilePath] 
 * and [filePath].
 */
class _RequestBundle {
  /// Hash value to request.
  final String hash;
  
  /// Path the downloaded file should be saved.
  final Path hashFilePath;
  
  /// Path to link there should link to [hashFilePath].
  final Path filePath;
  
  /// Create a [_RequestBundle] object.
  const _RequestBundle(this.hash, this.hashFilePath, this.filePath);
  
  /// Create link a link saved as [filePath] and links to [hashFilePath].
  Future createLink() {
    return _DartCodeDb.createLink(this.hashFilePath, this.filePath);
  }
  
  /// Save [data] into the file [hashFilePath].
  Future saveFile(List<int> data) {
    return new File.fromPath(hashFilePath).writeAsBytes(data);
  }
  
  /**
   * Calls both [saveFile] and [createLink] and returns a future there 
   * completes when both functions is finish. 
   */
  Future saveFileAndCreateLink(List<int> data) {
    saveFile(data).then((_) => createLink());
  }
}