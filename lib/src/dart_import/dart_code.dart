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
  /**
   * Should only be used by DartCode related classes. Please use [resolve] to
   * get an DartCode instance. 
   */
  DartCode(String name, 
           Path path, 
           List<int> hash, 
           List<DartCodeChild> dependencies) 
           : super(name,path,hash,dependencies);

  /**
   * Create DartCode object from URI to a valid Dart program. The DartCode
   * object contains information about all dependencies for the program.
   */
  static Future<DartCode> resolve(String uri, {bool useCache: true}) {
    _log("Running resolve($uri, $useCache)");
    
    return DartCodeDb.resolve(uri, useCache:useCache).then((DartCodeChild c) {
      DartCode code = new DartCode.fromDartCodeChild(c);
      code._shortenPaths();
      return code;
    });
  }
           
  /**
   *  Create DartCode object from DartCodeChild. The purpose is to upgrade a
   *  child node to a main node in the tree. Should only be used when you are
   *  sure the child node is actually the program you want to run.
   */
  DartCode.fromDartCodeChild(DartCodeChild child) : this(child.name, 
      child.path, 
      child._fileHash, 
      child._dependencies);
  
  /// Create DartCode object from JSON String.
  factory DartCode.fromJson(String jsonString) {
    return new DartCode.fromMap(json.parse(jsonString));
  }
  
  /// Create DartCode object from Map object (from json.parse()).
  factory DartCode.fromMap(Map map) {
    _log("Running DartCode.fromMap() for ${map[DartCodeChild._NAME]}");
    
    return new DartCode.fromDartCodeChild(new DartCodeChild.fromMap(map));
  }
  
  Future<String> createSpawnUriEnvironment() {
    Completer c = new Completer();
    
    Path workDirPath           = new Path(workDir);
    Path hashDirPath           = workDirPath.append("hashes/");
    Path isolateDirectoryPath  = workDirPath.append("isolates/");
    
    Directory hashDirectory    = new Directory.fromPath(hashDirPath);
    Directory isolateDirectory = new Directory.fromPath(isolateDirectoryPath);
    
    Future createHashDirFuture    = hashDirectory.create(recursive:true);
    Future createIsolateDirFuture = isolateDirectory.create(recursive:true);
    
    Future.wait([createHashDirFuture, createIsolateDirFuture]).then((_) {
      Path spawnDirectoryPath = isolateDirectoryPath.append(this.treeHash);
      File spawnFile = new File.fromPath(spawnDirectoryPath.join(this.path));
      
      _log(spawnFile.path);
      
      spawnFile.exists().then((bool fileExists) {
        if (fileExists) {
          // Get the full path and return it
          spawnFile.fullPath().then((String fullPath) {
            c.complete(fullPath);
          });
        } else {
          List<DartCodeChild> allFiles = _getTree(this);
          Set<Path> directoriesToCreate = new Set<Path>(); 

          // Create list of directories there is needed
          allFiles.forEach((DartCodeChild node) {
            Path directory = spawnDirectoryPath.join(node.path).directoryPath;
            directoriesToCreate.add(directory);
          });
          
          // Create needed directories
          Future.wait(directoriesToCreate.map((Path directoryPath) {
            Directory directory = new Directory.fromPath(directoryPath);
            return directory.create(recursive:true);
          })).then((_) {
            // This step insert the files into the environment. First its try
            // find the files in the HashDir and if this is not possible the
            // file will be downloaded from the network.
            Future.wait(allFiles.map((DartCodeChild node) {
              Path hashFilePath = hashDirPath.append("${node.fileHash}.dart");
              File hashFile = new File.fromPath(hashFilePath);
              
              Path filePath = spawnDirectoryPath.join(node.path);
              
              return hashFile.exists().then((bool hashFileExists) {
                if (!hashFileExists) {
                  // Connect to network, get the files and save them in hashes
                  return new File.fromPath(hashFilePath).create().then((_) {
                    return DartCodeDb.createLink(hashFilePath, filePath);
                  });
                }
                
                // Create link between hash file and the environment.
                return DartCodeDb.createLink(hashFilePath, filePath);
              });
            })).then((_) {
              // Get the full path and return it
              spawnFile.fullPath().then((String fullPath) {
                c.complete(fullPath);
              });
            });
          });
        }
      });
    });
    
    return c.future;
  }
  
  /*
   *  Because the operation can be a little CPU intensive we save this. There
   *  are no risks involved because the hashsum of each dependency of the 
   *  DartCode can't be changed after creation of the DartCode object.
   */
  String _treeHashCache = null;
  
  /**
   * Returns a calculated SHA1 checksum for the DartCode object and all the 
   * dependencies in the tree.  The purpose of this checksum is to make sure 
   * the checksum is different if there are changes in one of the files in the 
   * tree of [DartCode] objects.
   */
  String get treeHash {
    if (_treeHashCache == null) {
      SHA1 sum = new SHA1();
      sum.add(name.codeUnits);
      _getTree(this).forEach((DartCodeChild child) => sum.add(child._fileHash));
      return _hashListToString(sum.close());
    }
    return _treeHashCache;
  }
  
  /**
   * Takes the path from the DartCode object and all dependencies and removes
   * unnecessary parts of the path.  E.g.
   * 
   *     C:\Users\Dart\Code\Program.dart
   *     C:\Users\Dart\Code\Packages\important_lib.dart
   *     C:\Users\Dart\Code\Packages\data\model.dart
   *     C:\Users\Dart\Code\Packages\server\database.dart
   * 
   * This will change the paths into:
   * 
   *     Program.dart
   *     Packages\important_lib.dart
   *     Packages\data\model.dart
   *     Packages\server\database.dart
   * 
   * The purpose is to make the paths independent of the running system.
   */
  void _shortenPaths() {
    _log("Running _shortenPaths()");
    List<DartCodeChild> dependencies = _getTree(this).toList(growable:false);
    
    // Get all segments of all paths in dependencies and this DartCode instance.
    List<List<String>> paths = dependencies.map((DartCodeChild child) {
      return child.path.segments();
    }).toList(growable: true);
    
    int segmentsToRemove = _countEqualSegments(paths);
    
    dependencies.forEach((DartCodeChild node) {
      node._path = _removeSegmentsOfPath(node._path, segmentsToRemove);
    });
  }
  
  /**
   * Find the number of equal segments in a list of segments:
   * 
   *     List1 = [ "c", "Program Files", "Admin" ]
   *     List2 = [ "c", "Users", "Admin", "Test Data" ]
   *     List3 = [ "c", "Users", "Admin" ]
   * 
   * In this example we should return 1 because only 1 segment is equal in all
   * lists. We don't count equal segments after the first found of non-equal
   * list of segments (so "Admin" will not count here").
   */
  int _countEqualSegments(List<List<String>> paths) {
    _log("Running _countEqualSegments(");
    paths.forEach((List<String> x) => _log("     $x"));
    _log(");");
    
    int minSegmentLength = paths[0].length;
    
    // Get the size of the shortest list
    paths.forEach((List<String> segments) {
      if (segments.length < minSegmentLength) {
        minSegmentLength = segments.length;
      }
    });
    
    // Find the number of equal segments in a list of segments
    for (int i = 0; i < minSegmentLength; i++) {
      String compareValue = paths[0][i];
      
      for (int k = 0; k < paths.length; k++) {
        if (paths[k][i] != compareValue) {
          _log("Return value for _countEqualSegments() = $i");
          return i;
        }
      }
    }
    
    _log("Return value for _countEqualSegments() = $minSegmentLength");
    return minSegmentLength;
  }
  
  /**
   * Removes a number of segments of a given Path and creates a new Path with
   * the rest of segmenst. E.g.:
   * 
   *     Path p = new Path("C:\\User\\Dart\\Programs\\Fun\\main.dart");
   *     p = _removeSegmentsOfPath(p,3);
   *     p == new Path("Programs\\Fun\\main.dart");
   */
  Path _removeSegmentsOfPath(Path path, int segmentsToRemove) {
    StringBuffer sb = new StringBuffer();
    List<String> segments = path.segments();
    
    bool first = true;
    
    segments.skip(segmentsToRemove).forEach((String segment) {
      if (first) {
        first = false;
      } else {
        sb.write("/");
      }
      sb.write(segment);
    });
    
    return new Path(sb.toString());
  }
  
  /**
   * Get a list of the DartCode object and all dependencies needed to use the
   * DartCode object. This is not the same as [dependencies] because this method
   * also returns all dependencies of each dependency.
   */
  List<DartCodeChild> _getTree(DartCodeChild node) {
    _log("Running _getTree(${node.name})");
    
    List<DartCodeChild> nodes = node.dependencies.expand((DartCodeChild sub) {
      List<DartCodeChild> list = _getTree(sub);
      return list;
    }).toList(growable:true);
    nodes.add(node);

    return nodes;
  }
}