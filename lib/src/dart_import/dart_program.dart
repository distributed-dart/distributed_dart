part of distributed_dart;

/**
 * The purpose of this class is to represent a Dart program and its 
 * dependencies and make it possible to send and receive the object as JSON. 
 * All dependencies are represented as a set of unique [FileNode] objects.
 */
class DartProgram extends DependencyNode {
  static const String _NAME = "name";
  static const String _PATH = "path";
  static const String _HASH = "hash";
  static const String _DEPENDENCIES = "dependencies";

  DartProgram._internal(String name, Path path, List<int> hash, 
      List<FileNode> dependencies) : super(name,path,hash,dependencies);
  
  /**
   * Create [DartProgram] instance from [FileNode] or [DependencyNode] instance.
   * 
   * All dependencies are converted to [FileNode] instances and all paths are 
   * relative to the [DartProgram]. Because the paths are changed, the 
   * [DartProgram] instance will contain copies of [FileNode] instances and not 
   * the actual [FileNode] instances.
   */
  factory DartProgram(FileNode program) {
    if (program is DependencyNode) {
      Set set = new Set();
      
      program.dependencies.forEach((FileNode node) {
        set = node.getFileNodes(set);
      });
      
      List<FileNode> dependencies = set.map((FileNode node) {
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
      
      return new DartProgram._internal(program._name, 
                                       newPath, 
                                       program._fileHash,
                                       dependencies);
    } else {
      return new DartProgram._internal(program._name, 
                                       new Path(program.name), 
                                       program._fileHash,
                                       []);
    }
  }
  
  /// Create [DartProgram] instance from [String] containing a JSON object 
  /// (created from [toJson]).
  factory DartProgram.fromJson(String jsonString) {
    return new DartProgram.fromMap(json.parse(jsonString));
  }
  
  /// Create [DartProgram] from [Map] created by parsing a JSON object.
  factory DartProgram.fromMap(Map jsonMap) {
    List<FileNode> dependencies = new List<FileNode>();
    
    if (jsonMap.containsKey(_DEPENDENCIES) && jsonMap[_DEPENDENCIES] != null) {
      jsonMap[_DEPENDENCIES].forEach((Map fileNodeMap) {
        FileNode newNode = new FileNode(fileNodeMap[_NAME], 
                                        new Path(fileNodeMap[_PATH]),
                                        fileNodeMap[_HASH]);
        dependencies.add(newNode);
      });
    }
    
    return new DartProgram._internal(jsonMap[_NAME], new Path(jsonMap[_PATH]), 
                                     jsonMap[_HASH], dependencies);
  }
  
  /*
   *  Because the operation can be a little CPU intensive we save this. There
   *  are no risks involved because the hashsum of each dependency of the 
   *  DartProgram can't be changed after creation of the DartProgram object.
   */
  String _treeHashCache = null;
  
  /**
   * Returns a calculated SHA1 checksum for the [DartProgram] object and all the 
   * dependencies.  The purpose of this checksum is to make sure the checksum 
   * is different if there are changes in one of the dependencies.
   */
  String get treeHash {
    if (_treeHashCache == null) {
      SHA1 sum = new SHA1();
      sum.add(name.codeUnits);
      sum.add(this._fileHash);
      _dependencies.forEach((FileNode node) => sum.add(node._fileHash));
      _treeHashCache = _hashListToString(sum.close());
    }
    return _treeHashCache;
  }
  
  Map<String, Object> toJson() {
    _log("Running toJson() for $name");
    
    var returnMap = new Map();
    
    returnMap[_NAME] = this._name;
    returnMap[_PATH] = this._path.toString();
    returnMap[_HASH] = this._fileHash;
    
    if (this._dependencies != null && this._dependencies.length > 0) {
      returnMap[_DEPENDENCIES] = this._dependencies.map((FileNode node) {
        var map = new Map();
        
        map[_NAME] = node._name;
        map[_PATH] = node._path.toString();
        map[_HASH] = node._fileHash;
        
        return map;
      }).toList(growable: false);
    }
    
    return returnMap;
  }
  
  /**
   * Create an environment for the [DartProgram] and all dependencies and return 
   * the path to run (with e.g. [spawnUri]) as a [Future]. Missing files will be
   * downloaded. The created environment will be placed in the [workDir]
   * directory where also a cache will be created for previously dowloaded
   * files.
   */
  Future<String> createSpawnUriEnvironment() {
    _log("Running createSpawnUriEnvironment()");
    Completer c = new Completer();
    
    Path workDirPath           = new Path(workDir);
    Path hashDirPath           = workDirPath.append("hashes/");
    Path isolateDirectoryPath  = workDirPath.append("isolates/");
    
    _log("     workDirPath          = $workDirPath");
    _log("     hashDirPath          = $hashDirPath");
    _log("     isolateDirectoryPath = $isolateDirectoryPath");
    
    Directory hashDirectory    = new Directory.fromPath(hashDirPath);
    Directory isolateDirectory = new Directory.fromPath(isolateDirectoryPath);
    
    Future createHashDirFuture    = hashDirectory.create(recursive:true);
    Future createIsolateDirFuture = isolateDirectory.create(recursive:true);
    
    Future.wait([createHashDirFuture, createIsolateDirFuture]).then((_) {
      Path spawnDirectoryPath = isolateDirectoryPath.append(this.treeHash);
      File spawnFile = new File.fromPath(spawnDirectoryPath.join(this.path));
      
      _log("Spawn file path: ${spawnFile.path}");
      
      spawnFile.exists().then((bool fileExists) {
        if (fileExists) {
          c.complete(spawnFile.path);
        } else {
          Set<Path> directoriesToCreate = new Set<Path>(); 

          Set<FileNode> neededFiles = this.getFileNodes();
          
          // Create list of directories there is needed
          neededFiles.forEach((FileNode node) {
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
            List<RequestBundle> missingFiles = new List<RequestBundle>();
            
            Future.wait(neededFiles.map((FileNode node) {
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
                  missingFiles.add(new RequestBundle(node.fileHashString,
                                                       hashFilePath, filePath));
                  return;
                } else {
                  // Create link between hash file and the environment.
                  _log("Hashfile found in cache for: ${node.name}");
                  return DartCodeDb.createLink(hashFilePath, filePath);
                }
              });
            })).then((_) {
              if (missingFiles.length > 0) {
                _log("Download missing files from network:");
                DartCodeDb.downloadFilesAndCreateLinks(missingFiles).then((_) {
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