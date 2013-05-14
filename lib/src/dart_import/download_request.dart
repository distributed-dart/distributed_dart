part of distributed_dart;

class RequestPackage {
  final String hash;
  final Path hashFilePath;
  final Path filePath;
  
  const RequestPackage(this.hash, this.hashFilePath, this.filePath);
  
  Future createLink() {
    DartCodeDb.createLink(this.hashFilePath, this.filePath);
  }
}