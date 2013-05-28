part of distributed_dart;

/// Represents a file in the tree without dependencies.
class FileNode {
  String _name;
  Path _path;
  List<int> _fileHash;
  
  /// File name of the Dart file the object represent.
  String get name => _name;
  
  /// [Path] to the Dart file the object represent.
  Path get path => _path;
  
  /// SHA1 checksum of the Dart file the object represent as a [String].
  String get fileHashString => _hashListToString(_fileHash);
  
  List<int> get fileHash => _fileHash.toList(growable: false);
  
  /// Create FileNode instance. Should only be used by [DartCodeDb].
  FileNode(this._name, this._path, this._fileHash);
  
  Set<FileNode> getFileNodes([Set<FileNode> set]) {
    if (set == null) {
      set = new Set<FileNode>();
    }
    
    set.add(this);
    return set;
  }
  
  FileNode get copy => new FileNode(_name, _path, _fileHash);
  
  int get hashCode => _path.hashCode;
  
  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    
    if (other is FileNode) {
      if (_name != other._name) return false;
      if (_path.toString() != other._path.toString()) return false;
      if (!_compareLists(this._fileHash, other._fileHash)) return false;
      
      return true;
    } else {
      return false;
    }
  }
}