part of distributed_dart;

class DartCodeChild {
  static const String _NAME = "name";
  static const String _PATH = "path";
  static const String _HASH = "hash";
  static const String _DEPENDENCIES = "dependencies";
  
  /// File name of the Dart file the object represent.
  final String name;
  
  /// Full path to the Dart file the object represent.
  Path _path;
  
  /// SHA1 checksum of the Dart file the object represent.
  final List<int> _fileHash;
  
  /// List of dependenceies for the Dart file the object represent.
  final List<DartCodeChild> _dependencies;

  /// Create DartCode instance. Should only be used by [DartCodeDb].
  DartCodeChild(this.name, this._path, this._fileHash, this._dependencies);
  
  /// Create DartCode object from Map object (from json.parse()).
  factory DartCodeChild.fromMap(Map map) {
    _log("Running DartCodeChild.fromMap() for ${map[_NAME]}");
    
    List<DartCodeChild> dependencies;
    
    if (map.containsKey(_DEPENDENCIES) && map[_DEPENDENCIES] != null) {
      dependencies = new List<DartCodeChild>();
      
      map[_DEPENDENCIES].forEach((var dartCodeMap) {
        if (dartCodeMap != null) {
          dependencies.add(new DartCodeChild.fromMap(dartCodeMap));
        }
      });
    }
    
    Path path = new Path(map[_PATH]);
    return new DartCode(map[_NAME], path, map[_HASH], dependencies);
  }
  
  /**
   *  Path to the Dart file the object represent. The path is made as short as
   *  possible.
   */
  Path get path {
    return _path;
  }
  
  /// Return SHA1 checksum as a [String].
  String get fileHash {
    return _hashListToString(_fileHash);
  }
  
  /// Return SHA1 checksum as a [List<int>].
  List<int> get fileHashAsList {
    return _fileHash.toList(growable: false);
  }
  
  /**
   * Get a list of [DartCode] objects there are dependencies for this [DartCode]
   * instance. Each object in the list can also have dependencies.
   */
  List<DartCodeChild> get dependencies {
    return _dependencies.toList(growable: false);
  }
  
  // Simpel cache of DartCodeChild objects. If we
  List<DartCodeChild> _treeCache = null;
  
  /**
   * Get a list of the DartCodeChild object and all dependencies needed to use 
   * the DartCodeChild object. This is not the same as [dependencies] because 
   * this method also returns all dependencies of each dependency.
   */
  List<DartCodeChild> _getTree() {
    _log("Running _getTree(${this.name})");
    
    if (_treeCache != null) {
      /*
       * Dependency tree for X has already been calculated one time before and 
       * we are therefore using the result from last time.
       */
      _log("     _getTree(${this.name}): Using cached value.");
      return _treeCache;
    }
    _log("     _getTree(${this.name}): No cached value. Creating tree.");
    
    List<DartCodeChild> nodes = this.dependencies.expand((DartCodeChild sub) {
      List<DartCodeChild> list = sub._getTree();
      return list;
    }).toList(growable:true);
    nodes.add(this);

    _log("     _getTree(${this.name}): Added value to cache.");
    _treeCache = nodes;
    return nodes;
  }
  
  /**
  * Generate Map object from DartCode instance and is required to make it
  * possible to convert a DartCode instance to an JSON string.
  */
  Map<String, Object> toJson() {
    _log("Running toJson() for $name");
    
    var returnMap = new Map();
    
    returnMap[_NAME] = this.name;
    returnMap[_PATH] = this.path.toString();
    returnMap[_HASH] = this._fileHash;
    returnMap[_DEPENDENCIES] = this._dependencies;
    
    return returnMap;
  }
}