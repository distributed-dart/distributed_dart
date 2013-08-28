part of distributed_dart;

/// Represents a file in the tree with dependencies. (e.g. Dart file)
class _DependencyNode extends _FileNode {
  List<_FileNode> _dependencies;
  
  /**
   * Dependencies for the file this object represent. Dependencies can both be
   * [_FileNode] and [_DependencyNode] objects.
   */
  List<_FileNode> get dependencies => _dependencies.toList(growable: false);
  
  _DependencyNode(String path,
      List<int> fileHash, 
      this._dependencies) 
      : super(path,fileHash);
  
  /**
   * Returns a list of the object itself and all dependencies. The object
   * itself returned is a copy there is converted to a [_FileNode] instance.
   * 
   * All dependencies of the type [_DependencyNode] is also converted to
   * [_FileNode] instances. The purpose is to get a Set of all unique
   * dependencies there is needed for this node without any equal files.
   * 
   * The optional [set] parameter is the [Set] there will be used to hold all 
   * [_FileNode] instances. If no Set is given as parameter a new one is created.
   * 
   * The return value is the [Set] containing the dependencies.
   */
  Set<_FileNode> getFileNodes([Set<_FileNode> set]) {
    if (set == null) {
      set = new Set<_FileNode>();
    }
    
    set.add(new _FileNode(this._filePath, this._fileHash));
    _dependencies.forEach((_FileNode node) {
      set = node.getFileNodes(set);
    });
    return set;
  }
  
  int get hashCode => _filePath.hashCode;
  
  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    } else if (other is _DependencyNode) {
      if (_filePath != other._filePath) return false;
      if (_compareLists(_fileHash, other._fileHash)) return false;
      if (_dependencies != other._dependencies) return false;
      
      return true;
    } else {
      return false;
    }
  }
}