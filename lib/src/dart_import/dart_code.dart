part of distributed_dart;

class DartCode {
  static const String NAME = "name";
  static const String PATH = "path";
  static const String HASH = "hash";
  static const String DEPENDENCIES = "dependencies";
  
  final String name;
  final String path;
  final List<int> _hash;
  final List<DartCode> _dependencies;
  
  /**
   * Create DartCode instance. Should only be used by [DartCodeDb].
   */
  const DartCode(String this.name, String this.path, 
      List<int> this._hash, List<DartCode> this._dependencies);
  
  /**
   * Create DartCode object from JSON String.
   */
  factory DartCode.fromJson(String jsonString) {
    return new DartCode.fromJsonMap(json.parse(jsonString));
  }
  
  /**
   * Create DartCode object from Map object (from json.parse())
   */
  factory DartCode.fromJsonMap(Map jMap) {
    List<DartCode> dependenciesList;
    
    if (jMap.containsKey(DEPENDENCIES) && jMap[DEPENDENCIES] != null) {
      dependenciesList = new List<DartCode>();
      
      jMap[DEPENDENCIES].forEach((var jDartCodeMap) {
        if (jDartCodeMap != null) {
          dependenciesList.add(new DartCode.fromJsonMap(jDartCodeMap));
        }
      });
    }
    
    return new DartCode(jMap[NAME], jMap[PATH], jMap[HASH], dependenciesList);
  }
  
  List<DartCode> get dependencies {
    return _dependencies.toList(growable: false);
  }
  
  List<int> get fileHash {
    return _hash.toList(growable: false);
  }
  
  String get fileHashAsString {
    return _hashListToString(_hash);
  }
  
  List<int> get dartCodeHash {
    SHA1 sum = new SHA1();
    sum.add(name.codeUnits);
    sum.add(_hash);
    _dependencies.forEach((DartCode x) => sum.add(x._hash));
    return sum.close();
  }
  
  String get dartCodeHashAsString {
    return _hashListToString(dartCodeHash);
  }
  
  /**
   * Generate Map object from DartCode instance.
   */
  Map<String, Object> toJson() {
    var returnMap = new Map();
    
    returnMap[NAME] = this.name;
    returnMap[PATH] = this.path;
    returnMap[HASH] = this._hash;
    returnMap[DEPENDENCIES] = this._dependencies;  
    
    return returnMap;
  }
}
