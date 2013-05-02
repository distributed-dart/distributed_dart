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
class DartCode {
  static const String _NAME = "name";
  static const String _PATH = "path";
  static const String _HASH = "hash";
  static const String _DEPENDENCIES = "dependencies";
  
  /// File name of the Dart file the object represent.
  final String name;
  
  /// Full path to the Dart file the object represent.
  final String path;
  
  /// SHA1 checksum of the Dart file the object represent.
  final List<int> _hash;
  
  /// List of dependenceies for the Dart file the object represent.
  final List<DartCode> _dependencies;
  
  /// Create DartCode instance. Should only be used by [DartCodeDb].
  const DartCode(String this.name, String this.path, 
      List<int> this._hash, List<DartCode> this._dependencies);
  
  /// Create DartCode object from JSON String.
  factory DartCode.fromJson(String jsonString) {
    return new DartCode.fromJsonMap(json.parse(jsonString));
  }
  
  /// Create DartCode object from Map object (from json.parse()).
  factory DartCode.fromJsonMap(Map jMap) {
    List<DartCode> dependencies;
    
    if (jMap.containsKey(_DEPENDENCIES) && jMap[_DEPENDENCIES] != null) {
      dependencies = new List<DartCode>();
      
      jMap[_DEPENDENCIES].forEach((var jDartCodeMap) {
        if (jDartCodeMap != null) {
          dependencies.add(new DartCode.fromJsonMap(jDartCodeMap));
        }
      });
    }
    
    return new DartCode(jMap[_NAME], jMap[_PATH], jMap[_HASH], dependencies);
  }
  
  /**
   * Get a list of [DartCode] objects there are dependencies for this [DartCode]
   * instance. Each object in the list can also have dependencies.
   */
  List<DartCode> get dependencies {
    return _dependencies.toList(growable: false);
  }
  
  /// Return SHA1 checksum of the DartFile as a list of [int].
  List<int> get fileHash {
    return _hash.toList(growable: false);
  }
  
  /// Return SHA1 checksum of the DartFile as a [String].
  String get fileHashAsString {
    return _hashListToString(_hash);
  }
  
  /***
   * Returns a calculated SHA1 checksum for the DartCode object and all the 
   * dependencies in the tree.  The purpose of this checksum is to make sure 
   * the checksum is different if there are changes in one of the files in the 
   * tree of [DartCode] objects.
   */
  List<int> get dartCodeHash {
    SHA1 sum = new SHA1();
    sum.add(name.codeUnits);
    sum.add(_hash);
    _dependencies.forEach((DartCode x) => sum.add(x._hash));
    return sum.close();
  }
  
   /// Do the same as [dartCodeHash] but returns the SHA1 checksum as a String.
  String get dartCodeHashAsString {
    return _hashListToString(dartCodeHash);
  }
  
  /**
   * Generate Map object from DartCode instance and is required to make it 
   * possible to convert a DartCode instance to an JSON string.
   */
  Map<String, Object> toJson() {
    var returnMap = new Map();
    
    returnMap[_NAME] = this.name;
    returnMap[_PATH] = this.path;
    returnMap[_HASH] = this._hash;
    returnMap[_DEPENDENCIES] = this._dependencies;  
    
    return returnMap;
  }
}
