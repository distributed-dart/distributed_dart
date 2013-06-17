part of distributed_dart;

/**
 * Contains only static methods and variables (but is placed inside a class to 
 * encapsulate). The purpose of these methods is to give access to various IO 
 * operations in the library.
 * 
 * Another detail is the class also contains static data to be used as cache in 
 * various places. The cache contains content from files there have been loaded 
 * before. The purpose is to give fast access to this data without waiting for 
 * the disk.
 */
class DartCodeDb {
  /*
   * Resolve a given Path into a cached FileNode instance. If a Path is 
   * already parsed one time we don’t need to do it again.
   * 
   * Path => FileNode instance (as future)
   */
  static Map<Path,Future<FileNode>> _pathToFileNode = new Map();
  
  /*
   * Resolve a given hash checksum value into to content of the file. Because we 
   * know the file must have been read one time before (when created 
   * FileNode object) we can use this cache when trying to send files to 
   * other machines on the network.
   * 
   * Hash => Source code as List<int> (as future)
   */
  static Map<String,Future<List<int>>> _sourceCache = new Map();
  
  /*
   * The purpose of this cache is to resolve the path of a given hash sum 
   * in the case of the cache has been emptied (several possible reasons for 
   * doing this). By clean the cache the program doesn’t contains the content 
   * of the file but we still want to be able to give access to the content.
   */
  static Map<String,Path> _hashToPathCache = new Map();
  
  /**
   * **NOTE: This method is not implemented correctly right now!**
   * 
   * Instead of getting the content from the disk it should take a network 
   * object and use it to send a request for the file content (and save it 
   * locally after). The reason for current foolish implementation is to test 
   * if things work without the network implementation finished.
   * 
   * Download file requests by create a network request, send it to the network 
   * and wait for the answer. When all the files is downloaded it is saved to 
   * the disk locally and linked to the right directories as described in the 
   * [RequestBundle] objects. The returned [Future] is finished when all steps 
   * in the process is finished.
   */
  static Future downloadFilesAndCreateLinks(List<RequestBundle> requests) {
    if (logging) {
      _log("Running downloadFilesAndCreateLinks(");
      requests.forEach((RequestBundle r) {
        _log("     ${r.hash}:");
        _log("        hashFilePath: ${r.hashFilePath}");
        _log("        filePath:     ${r.filePath}");
      });
    }
    
    return Future.wait(requests.map((RequestBundle r) {
      return getSourceFromHash(r.hash).then((List<int> fileContent) {
        File newFile = new File.fromPath(r.hashFilePath);
        
        return newFile.writeAsBytes(fileContent).then((_) {
          return r.createLink();
        });
      });
    }));
  }
  
  /**
   * Create [DartProgram] object from URI to a valid Dart program. The 
   * [DartProgram] object contains information about all dependencies for 
   * the program.
   * 
   * [useCache] should be set to false if some of the files has been changed
   * on the filesystem while the program has been running.
   */
  static Future<DartProgram> resolveDartProgram(String uri, 
                                                {bool useCache: true}) {
    _log("Running resolveDartProgram($uri, $useCache)");
    
    return new File(uri).fullPath().then((String path) {
      Path dir = new Path(path).directoryPath;
      Path packageDir = dir.append("packages");
      
      return DartCodeDb._resolve(path, packageDir, useCache:useCache).then(
          (FileNode node) {
            DartProgram code = new DartProgram(node);
            return code;
          });
    });
  }
  
  /**
   * Resolve a URI into a [FileNode] object. This method looks like the 
   * same as [DartCodeDb.resolveDartProgram] but the main difference is this 
   * method returns a [FileNode] object when the [DartCodeDb.resolveDartProgram] 
   * method returns a [DartProgram] object. The reason for this design is 
   * [DartCodeDb._resolve] is designed to be called recursive.
   * 
   * [useCache] should be set to false if some of the files has been changed
   * on the filesystem while the program has been running.
   */
  static Future<FileNode> _resolve(String uri, 
                                  Path packageDir, 
                                  {bool useCache: true} ) {
    
    _log("Running DartCodeDb.resolve($uri, $useCache)");
    File sourceFile = new File(uri);
    
    Path path = new Path(uri);
    Path dir = path.directoryPath;
    
    Future<FileNode> node;
    
    if (useCache) {
      _log("Looking in cache for FileNode object.");
      node = _pathToFileNode[path];
      
      if (node != null) {
        _log("Found FileNode object in cache and return it.");
        return node;
      }
      _log("Did not found FileNode object in cache.");
    }

    _log("Create new FileNode object (queue async file read).");
    node = sourceFile.readAsBytes().then((List<int> bytes) {
      _log("Finish reading and now working on: $uri");
      
      // Calculate SHA1 hashsum of the file.
      _log("Calculate SHA1 checksum.");
      SHA1 sha1 = new SHA1();
      sha1.add(bytes);
      List<int> hash = sha1.close();
      _log("SHA1 checksum is: ${_hashListToString(hash)}");
      
      /*
       *  Save the file content in cache (the file content is already loaded
       *  so we can insert the value directly in the future). Also map the
       *  hash with the path so we can get the path later if only knowing the
       *  hash value.
       */
      _log("Saving information in _sourceCache and _hashToPathCache.");
      String hashString = _hashListToString(hash);
      _sourceCache[hashString] = new Future.value(bytes);
      _hashToPathCache[hashString] = path;
      
      String extension = path.extension.toLowerCase();
      _log("The extension of the file is: $extension");
      
      // File there specify additional dependencies
      if (extension == "distdartdeps") {
        _log("'distdartdeps' extension so we scan for dependencies.");
        
        return new Stream.fromIterable([bytes]).transform(new StringDecoder())
          .transform(new LineTransformer())
          .transform(new StreamTransformer<String, Future<FileNode>>(
            handleData: (String depUri, EventSink<Future<FileNode>> sink) {
              String depUriTrim = depUri.trim();
              
              // If started with # it is a comment and should be ignored
              if (!depUriTrim.isEmpty && !depUriTrim.startsWith("#")) {
                String file = dir.join(new Path(depUriTrim)).toNativePath();
                sink.add(_resolve(file, packageDir, useCache: useCache));  
              }
          })).toList().then((List<Future<FileNode>> dependencies) {
            return Future.wait(dependencies).then((List<FileNode> list) {
              if (list.length > 0) {
                return new DependencyNode(path, hash, list);
              } else {
                return new FileNode(path, hash);
              }
            });
          });
      }
      
      // Only scan Dart files. All other files should just be accepted.
      if (extension != "dart") {
        _log("File is not distdartdeps or dart so we just return it.");
        return new FileNode(path, hash);
      }
      
      // Parse the Dart file with the scanner and get dependencies
      _log("File is a dart file.");
      _log("Create and run scanner for: $uri");
      Runes runes = (new String.fromCharCodes(bytes)).runes;
      _log("Runes created!");
      
      Scanner scanner = new Scanner(runes);
      _log("Scanner created!");
      
      Set<String> dependencies = scanner.getDependencies().toSet();
      _log("Got list of dependencies: $dependencies");
      
      // Resolve each dependency to full path (and ignore dart sdk stuff)
      return Future.wait(dependencies.where((String path) {
        if (path.startsWith("dart:")) {
          _log("Ignore dependency (part of Dart SDK): $path");
          return false;
        } else {
          _log("Dependency found: $path"); 
          return true;
        }
      }).map((String path) {
        Path filePath;
        
        if (path.startsWith("package:")) {
          _log("Dependency use the package dir: $path");
          String pathString = path.substring("package:".length);
          filePath = packageDir.append(pathString);
        } else {
          _log("Normal Dependency without package: $path");
          filePath = dir.append(path);
        }
        _log("    Full path is: ${filePath.toNativePath()}");
        
        _log("Create async task with: resolve(");
        _log("(${filePath.toNativePath()}, $packageDir, useCache:$useCache))");
        
        return _resolve(filePath.toNativePath(), packageDir, useCache:useCache);
      })).then((List<FileNode> dependencies) {
        if (dependencies.length > 0) {
          return new DependencyNode(path,hash,dependencies);
        } else {
          return new FileNode(path,hash); 
        }
      });
    }).then((FileNode origNode) {
      _log("Got all dependencies for $uri");
      
      if (origNode.name.endsWith(".distdartdeps")) {
        _log("File is a .distdartdeps file so we just return it.");
        return origNode;
      }
      
      String distDartDepsFile = "${path.toNativePath()}.distdartdeps";
      
      _log("Create async task to check existence of file: $distDartDepsFile");
      return new File(distDartDepsFile).exists().then((bool fileExists) {
        _log("Result for check file existence of $distDartDepsFile:");
        if (fileExists) {
          _log("File exist. We resolve it: resolve(");
          _log("($distDartDepsFile, $packageDir, useCache:$useCache))");
          
          return _resolve(distDartDepsFile, packageDir, useCache:useCache).then(
              (FileNode node) {
                if (origNode is DependencyNode) {
                  _log("Original node is a DependencyNode.");
                  
                  List<FileNode> newDependencies = 
                      origNode._dependencies.toList(growable:true);
                  
                  newDependencies.add(node);
                  
                  origNode._dependencies = newDependencies;
                  return origNode;
                } else {
                  _log("Convert original FileNode to DependencyNode.");
                  
                  return new DependencyNode(origNode.path, 
                                            origNode.fileHash, [node]);
                }
              });
        } else {
          _log("No such file exist so we just return the FileNode.");
          return origNode;
        }
      });
    });
    
    /*
     * I don't know if this is smart but I think we should always save the
     * object in cache regardless if the user want to use the cache to get
     * the object.
     */
    _log("Save new FileNode object in cache.");
    _pathToFileNode[path] = node;
    return node;
  }
  
  /**
   * Clear the cache containing the content of files there has been read before.
   * The reason why there is only one method is it doesn’t make much sense to 
   * clear the other caches without clean the file content cache.
   */
  static void clearFileContentCache({bool clearHashToPathCache:false,
                                     bool clearDartCodeCache:false}) {
    if (clearHashToPathCache) {
      _hashToPathCache.clear();
    }
    
    if (clearDartCodeCache) {
      _pathToFileNode.clear();
    }
    
    _sourceCache.clear();
  }
  
  /**
   * Resolve hash checksum into the content of the actual file. The files there
   * are possible to resolve is files there are already read by other pieces of
   * code in the program.
   * 
   * Throw [FileChangedException] in case of the cache has been cleared and the
   * file is changed (if the new hash checksum is not the same as the
   * requested).
   * 
   * [canAddToCache] is used if the file content of the needed file is removed
   * by cleaning the cache. By using a cache it is possible to resolve the path
   * by using the hash. If [canAddToCache] is false the content cache will not
   * be updated with the content of the loaded file.
   */
  static Future<List<int>> getSourceFromHash(String hash, {canAddToCache:true}){
    Future<List<int>> cacheContent = _sourceCache[hash];
    
    if (cacheContent != null) {
      // We are lucky. The file is directly found in the file content cache.
      return cacheContent;
    } else {
      Path contentPath = _hashToPathCache[hash];
      
      if (contentPath != null) {
        // The file is not found in cache but the path is. Now we try read from
        // the path.
        File contentFile = new File.fromPath(contentPath);
        
        Future<List<int>> content;
        
        content = contentFile.readAsBytes().then((List<int> fileContent) {
          SHA1 sha1 = new SHA1();
          sha1.add(fileContent);
          String newHash = _hashListToString(sha1.close());
          
          if (hash == newHash) {
            // The file has not changed from last time we read it
            // so we can use it.
            return fileContent;
          } else {
            /*
             * Well this is awkward. The file has changed and we don’t know the 
             * placement of another file with the same hash checksum. We need to
             * throw an exception.
             */
            String e = "Hash of the file has changed: Old=$hash New=$newHash";
            throw new FileChangedException("Hash sum is not the same. $e");
          }
        });
        
        /*
         * If canAddToCache is true we are allowed to change the file
         * content cache and add the file content to this cache. 
         */
        if (canAddToCache) {
          _sourceCache[hash] = content;
        }
        return content;
        
      } else {
        // The file is not found in the cache and we don't have en path of it
        // in the _hashToPathCache. Well, time to return an exception.
        String e = "Could not find a file with hash: $hash";
        throw new FileNotFoundException(e);
      }
    }
  }
  
  /**
   * This method exists because Windows don’t support symlinks (or similar 
   * feature) for files without additional permissions. Because of this 
   * restriction it is not possible to use the Dart class 
   * [Link](http://api.dartlang.org/docs/releases/latest/dart_io/Link.html) on 
   * Windows systems. The purpose of the method is therefore to use different 
   * implementation on different systems.
   * 
   * On Windows we use hardlinks because they are possible to use without 
   * additional permissions. Dart do not support creating hardlinks so we call 
   * the [:mklink:] command from the Windows cmd instead.
   * 
   * On all other systems we use the 
   * [Link](http://api.dartlang.org/docs/releases/latest/dart_io/Link.html) 
   * class to create symlinks.
   */
  static Future createLink(Path source, Path destination) {
    _log("Running createLink(${source.toString()}, ${destination.toString()})");
    
    Completer c = new Completer();
    
     _log("OS found: ${Platform.operatingSystem}.");
    if (Platform.operatingSystem == "windows") {
      _log("Create hardlink by using 'mklink'.");
      /* 
       * Windows don't support symlinks (only junctions and that is only 
       * supported if the user has the right permissions. Instead we use
       * hardlinks on Windows (funny that is okey but not symlinks...)
       * 
       * WARNING: This fix will properly not work on Windows XP because the need
       * of the mklink command.
       */
      List<String> arguments = ["/C",
                                "mklink",
                                "/H",
                                destination.toNativePath(), 
                                source.toNativePath()];
      
      if (logging) {
        StringBuffer sb = new StringBuffer("cmd");
        arguments.forEach((String argument) {
          sb.write(" $argument");
        });
        _log("Starting new process: ${sb.toString()}.");
      }
      Process.run("cmd", arguments).then((ProcessResult result) {
        _log("Result from process for link creation:");
        _log("     Link destination: ${destination.toNativePath()}");
        _log("     Link source: ${source.toNativePath()}");
        
        if (!result.stdout.isEmpty) _log("     stdout: ${result.stdout}");
        
        if (!result.stderr.isEmpty) {
          _err("     Link destination: ${destination.toNativePath()}");
          _err("     Link source: ${source.toNativePath()}");
          _err("     stderr: ${result.stderr}");
        }
        
        if (result.stderr.isEmpty) {
          _log("Link succesfully created.");
          c.complete();
        } else {
          OSError osError = new OSError(result.stderr, result.exitCode);
          throw new FileIOException("Could not create link.", osError);
        }
      });
      
    } else {
      _log("Create hardlink by using Dart own Link class.");
      
      StringBuffer sb = new StringBuffer();
      for (int a = 1; a < destination.segments().length; a++) {
        sb.write("../");
      }
      
      Path releativeSource = new Path(sb.toString() + source.toString());
      
      Link link = new Link.fromPath(destination);
      link.create(releativeSource.toString()).then((_) {
        _log("Link succesfully created:");
        _log("     Link destination: ${destination.toNativePath()}");
        _log("     Link source: ${releativeSource.toNativePath()}");
        c.complete();
      });
    }
    
   return c.future;
  }
}
