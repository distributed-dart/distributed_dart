part of distributed_dart;

/// Represents a file in the tree with dependencies. (e.g. Dart file)
class DependencyNode extends FileNode {
  List<FileNode> _dependencies;
  
  /**
   * Dependencies for the file this object represent. Dependencies can both be
   * [FileNode] and [DependencyNode] objects.
   */
  List<FileNode> get dependencies => _dependencies.toList(growable: false);
  
  DependencyNode(Path path,
      List<int> fileHash, 
      this._dependencies) 
      : super(path,fileHash);
  
  /**
   * Returns a list of the object itself and all dependencies. The object
   * itself returned is a copy there is converted to a [FileNode] instance.
   * 
   * All dependencies of the type [DependencyNode] is also converted to
   * [FileNode] instances. The purpose is to get a Set of all unique
   * dependencies there is needed for this node without any equal files.
   * 
   * The optional [set] parameter is the [Set] there will be used to hold all 
   * [FileNode] instances. If no Set is given as parameter a new one is created.
   * 
   * The return value is the [Set] containing the dependencies.
   */
  Set<FileNode> getFileNodes([Set<FileNode> set]) {
    if (set == null) {
      set = new Set<FileNode>();
    }
    
    set.add(new FileNode(this._path, this._fileHash));
    _dependencies.forEach((FileNode node) {
      set = node.getFileNodes(set);
    });
    return set;
  }
  
  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    } else if (other is DependencyNode) {
      if (_path != other._path) return false;
      if (_compareLists(_fileHash, other._fileHash)) return false;
      if (_dependencies != other._dependencies) return false;
      
      return true;
    } else {
      return false;
    }
  }
}