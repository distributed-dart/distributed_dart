part of distributed_dart;

/// Represents a file in the tree without dependencies.
class FileNode {
  Path _path;
  List<int> _fileHash;

  FileNode(this._path, this._fileHash);
  
  /// File name of the file the object represent.
  String get name => _path.filename;
  
  /// [Path] to the file the object represent.
  Path get path => _path;
  
  /// SHA1 checksum of the file the object represent as a [String].
  String get fileHashString => _hashListToString(_fileHash);
  
  /// SHA1 checksum of the file the object represent as a [List<int>]. The 
  /// returned list is not growable.
  List<int> get fileHash => _fileHash.toList(growable: false);
  
  /// Insert this object into a [Set] and return the [Set]. If [set] is
  /// provided the method will use this [Set] instead of creating a new one.
  Set<FileNode> getFileNodes([Set<FileNode> set]) {
    if (set == null) {
      set = new Set<FileNode>();
    }
    set.add(this);
    return set;
  }
  
  /// Returns a copy of this object.
  FileNode get copy => new FileNode(_path, _fileHash);
  
  int get hashCode => _path.hashCode;
  
  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    
    if (other is FileNode) {
      if (_path.toString() != other._path.toString()) return false;
      if (!_compareLists(this._fileHash, other._fileHash)) return false;
      
      return true;
    } else {
      return false;
    }
  }
}