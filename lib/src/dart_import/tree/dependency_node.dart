part of distributed_dart;

/// Represents a file in the tree which can have dependencies. (e.g. Dart file)
class DependencyNode extends FileNode {
  List<FileNode> _dependencies;
  
  List<FileNode> get dependencies => _dependencies.toList(growable: false);
  
  DependencyNode(String name, 
      Path path, 
      List<int> fileHash, 
      this._dependencies) 
      : super(name,path,fileHash);
  
  Set<FileNode> getFileNodes(Set<FileNode> set) {
    set.add(new FileNode(this._name, this._path, this._fileHash));
    _dependencies.forEach((FileNode node) {
      set = node.getFileNodes(set);
    });
    return set;
  }
  
  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    }
    
    if (other is DependencyNode) {
      if (_name != other._name) return false;
      if (_path != other._path) return false;
      if (_compareLists(_fileHash, other._fileHash)) return false;
      if (_dependencies != other._dependencies) return false;
      
      return true;
    } else {
      return false;
    }
  }
}