part of distributed_dart;

/**
 * The purpose of the class is representing a Dart program and the programs 
 * dependencies. The following informations is saved inside the class:
 * 
 * * File Name.
 * * Full path.
 * * SHA1 checksum.
 * * Dependencies to other Dart files.
 * 
 * Please notice the class doesn’t contains the actual source code of the
 * program. To get the source code of an [DartCode] instance please use the
 * [DartCodeDb] class.
 */
class DartCode extends DartCodeChild {
  // Stupid hack because we can't extend and get static variables :(
  static const String _NAME         = DartCodeChild._NAME;
  static const String _PATH         = DartCodeChild._PATH;
  static const String _HASH         = DartCodeChild._HASH;
  static const String _DEPENDENCIES = DartCodeChild._DEPENDENCIES;
  
  DartCode(String name, 
           String path, 
           List<int> hash, 
           List<DartCodeChild> dependencies) 
           : super(name,path,hash,dependencies) {
              _shortenPaths();
           }
  
  static Future<DartCode> resolve(String uri, {bool useCache: true}) {
    return DartCodeDb.resolve(uri, useCache:useCache);
  }
  
  /// Create DartCode object from DartCodeChild.
  DartCode.fromDartCodeChild(DartCodeChild c) : this(c.name, 
                                                     c.path, 
                                                     c._fileHash, 
                                                     c.dependencies);
  
  /// Create DartCode object from JSON String.
  factory DartCode.fromJson(String jsonString) {
    return new DartCode.fromMap(json.parse(jsonString));
  }
  
  /// Create DartCode object from Map object (from json.parse()).
  factory DartCode.fromMap(Map map) {
    List<DartCodeChild> dependencies;
    
    if (map.containsKey(_DEPENDENCIES) && map[_DEPENDENCIES] != null) {
      dependencies = new List<DartCodeChild>();
      
      map[_DEPENDENCIES].forEach((var dartCodeMap) {
        if (dartCodeMap != null) {
          dependencies.add(new DartCodeChild.fromMap(dartCodeMap));
        }
      });
    }
    
    return new DartCode(map[_NAME], map[_PATH], map[_HASH], dependencies);
  }
  
  /***
   * Returns a calculated SHA1 checksum for the DartCode object and all the 
   * dependencies in the tree.  The purpose of this checksum is to make sure 
   * the checksum is different if there are changes in one of the files in the 
   * tree of [DartCode] objects.
   */
  String get treeHash {
    SHA1 sum = new SHA1();
    sum.add(name.codeUnits);
    sum.add(_fileHash);
    _allChild(this).forEach((DartCodeChild child) => sum.add(child._fileHash));
    return _hashListToString(sum.close());
  }
  
  void _shortenPaths() {
    List<DartCodeChild> children = _allChild(this).toList(growable: false);
    
    Path basePath = new Path(this.path).directoryPath;
    int segmentsInBasePath = basePath.segments().length;
    
    children.forEach((DartCodeChild child) {
      Path check = new Path(child.path).directoryPath;
      int segmentsInCheck = check.segments().length;
      
      if (segmentsInCheck < segmentsInBasePath) {
        basePath = check;
        segmentsInBasePath = segmentsInCheck;
      }
    });
    
    children.forEach((DartCodeChild child) {
      child._path = new Path(child.path).relativeTo(basePath).toString();
    });
  }
  
  Iterable<DartCodeChild> _allChild(DartCodeChild child) {
    return child.dependencies.expand((DartCodeChild subChild) 
        => subChild.dependencies.expand((DartCodeChild subsubChild) 
            => _allChild(subsubChild)));
  }
}
