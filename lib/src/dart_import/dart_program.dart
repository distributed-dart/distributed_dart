part of distributed_dart;

/**
 * The purpose of this class is to represent a Dart program and its 
 * dependencies and make it possible to send and receive the object as JSON. 
 * All dependencies are represented as a set of unique [_FileNode] objects.
 */
class _DartProgram extends _DependencyNode {
  static const String _NAME = "name";
  static const String _PATH = "path";
  static const String _HASH = "hash";
  static const String _DEPENDENCIES = "dependencies";

  _DartProgram._internal(Path path, List<int> hash, List<_FileNode> dependencies)
    : super(path,hash,dependencies);
  
  /**
   * Create [_DartProgram] instance from [_FileNode] or [_DependencyNode] instance.
   * 
   * All dependencies are converted to [_FileNode] instances and all paths are 
   * relative to the [_DartProgram]. Because the paths are changed, the 
   * [_DartProgram] instance will contain copies of [_FileNode] instances and not 
   * the actual [_FileNode] instances.
   */
  factory _DartProgram(_FileNode program) {
    if (program is _DependencyNode) {
      Set set = new Set();
      
      program.dependencies.forEach((_FileNode node) {
        set = node.getFileNodes(set);
      });
      
      List<_FileNode> dependencies = set.map((_FileNode node) {
        return node.copy;
      }).toList(growable: true);
      
      /*
       * Convert all paths into relative paths by remove all parts of each path
       * there are equal to all others.
       * 
       * To also do this on the main program we add the program into the list of
       * dependencies temporary and remove it again. When we remove the object
       * from the list we save the path and use it when creating the DartProgram
       * object.
       */
      dependencies.add(program.copy);
      _shortenPaths(dependencies);
      Path newPath = dependencies.removeLast()._path;
      
      return new _DartProgram._internal(newPath,
                                       program._fileHash,
                                       dependencies);
    } else {
      return new _DartProgram._internal(new Path(program.name),
                                       program._fileHash,
                                       []);
    }
  }
  
  /// Create [_DartProgram] instance from [String] containing a JSON object 
  /// (created from [toJson]).
  factory _DartProgram.fromJson(String jsonString) {
    return new _DartProgram.fromMap(json.parse(jsonString));
  }
  
  /// Create [_DartProgram] from [Map] created by parsing a JSON object.
  factory _DartProgram.fromMap(Map jsonMap) {
    List<_FileNode> dependencies = new List<_FileNode>();
    
    if (jsonMap.containsKey(_DEPENDENCIES) && jsonMap[_DEPENDENCIES] != null) {
      jsonMap[_DEPENDENCIES].forEach((Map fileNodeMap) {
        _FileNode newNode = new _FileNode(new Path(fileNodeMap[_PATH]), 
                                        fileNodeMap[_HASH]);
        dependencies.add(newNode);
      });
    }
    
    return new _DartProgram._internal(new Path(jsonMap[_PATH]), jsonMap[_HASH],
                                     dependencies);
  }
  
  /*
   *  Because the operation can be a little CPU intensive we save this. There
   *  are no risks involved because the hashsum of each dependency of the 
   *  DartProgram can't be changed after creation of the DartProgram object.
   */
  String _treeHashCache = null;
  
  /**
   * Returns a calculated SHA1 checksum for the [_DartProgram] object and all the 
   * dependencies.  The purpose of this checksum is to make sure the checksum 
   * is different if there are changes in one of the dependencies.
   */
  String get treeHash {
    if (_treeHashCache == null) {
      SHA1 sum = new SHA1();
      sum.add(name.codeUnits);
      sum.add(this._fileHash);
      _dependencies.forEach((_FileNode node) => sum.add(node._fileHash));
      _treeHashCache = _hashListToString(sum.close());
    }
    return _treeHashCache;
  }
  
  Map<String, Object> toJson() {
    _log("Running toJson() for $name");
    
    var returnMap = new Map();
    
    returnMap[_PATH] = this._path.toString();
    returnMap[_HASH] = this._fileHash;
    
    if (this._dependencies != null && this._dependencies.length > 0) {
      returnMap[_DEPENDENCIES] = this._dependencies.map((_FileNode node) {
        var map = new Map();
        
        map[_PATH] = node._path.toString();
        map[_HASH] = node._fileHash;
        
        return map;
      }).toList(growable: false);
    }
    
    return returnMap;
  }
  
  /**
   * Create an environment for the [_DartProgram] and all dependencies and return 
   * the path to run (with e.g. [spawnUri]) as a [Future]. Missing files will be
   * downloaded. The created environment will be placed in the [workDir]
   * directory where also a cache will be created for previously dowloaded
   * files.
   */
  Future<String> createSpawnUriEnvironment() {
    _log("Running createSpawnUriEnvironment()");
    Completer c = new Completer();
    
    Path hashDirPath     = _workDirPath.append("hashes/");
    Path isolateDirPath  = _workDirPath.append("isolates/");
    
    _log("     workDirPath          = $_workDirPath");
    _log("     hashDirPath          = $hashDirPath");
    _log("     isolateDirectoryPath = $isolateDirPath");
    
    Directory hashDirectory    = new Directory.fromPath(hashDirPath);
    Directory isolateDirectory = new Directory.fromPath(isolateDirPath);
    
    Future createHashDirFuture    = hashDirectory.create(recursive:true);
    Future createIsolateDirFuture = isolateDirectory.create(recursive:true);
    
    Future.wait([createHashDirFuture, createIsolateDirFuture]).then((_) {
      Path spawnDirectoryPath = isolateDirPath.append(this.treeHash);
      File spawnFile = new File.fromPath(spawnDirectoryPath.join(this.path));
      
      _log("Spawn file path: ${spawnFile.path}");
      
      spawnFile.exists().then((bool fileExists) {
        if (fileExists) {
          c.complete(spawnFile.path);
        } else {
          Set<Path> directoriesToCreate = new Set<Path>(); 

          Set<_FileNode> neededFiles = this.getFileNodes();
          
          // Create list of directories there is needed
          neededFiles.forEach((_FileNode node) {
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
            List<_RequestBundle> missingFiles = new List<_RequestBundle>();
            
            Future.wait(neededFiles.map((_FileNode node) {
              Path hashFilePath = 
                  hashDirPath.append("${node.fileHashString}.dart");
              
              File hashFile = new File.fromPath(hashFilePath);
              
              Path filePath = spawnDirectoryPath.join(node.path);
              _log("spawnDirectoryPath: $spawnDirectoryPath");
              _log("node.path: ${node.path}");
              
              return hashFile.exists().then((bool hashFileExists) {
                if (!hashFileExists) {
                  // Add file to list of files to download
                  _log("Add missing file to download list: ${node.name}");
                  missingFiles.add(new _RequestBundle(node.fileHashString,
                                                       hashFilePath, filePath));
                  return;
                } else {
                  // Create link between hash file and the environment.
                  _log("Hashfile found in cache for: ${node.name}");
                  return _DartCodeDb.createLink(hashFilePath, filePath);
                }
              });
            })).then((_) {
              if (missingFiles.length > 0) {
                _log("Download missing files from network:");
                _DartCodeDb.downloadFilesAndCreateLinks(missingFiles).then((_) {
                  c.complete(spawnFile.path);
                });
              } else {
                // Get the full path and return it
                c.complete(spawnFile.path);
              }
            });
          });
        }
      });
    });
    
    return c.future.then((String path) {
      // Append current working directory for the running Dart process
      Path processDir = new Path(Directory.current.path);
      String fullPath = processDir.append(path).toNativePath();
      
      _log("Append current process working directory:");
      _log("     File to spawn:     $path");
      _log("     Process directory: ${processDir.toString()}");
      _log("     Full path:         $fullPath");
      
      return fullPath;
    });
  }
}