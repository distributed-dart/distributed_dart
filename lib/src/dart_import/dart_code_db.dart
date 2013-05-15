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
   * Resolve a given Path into a cached DartCodeChild instance. If a Path is 
   * already parsed one time we don’t need to do it again.
   * 
   * Path => DartCodeChild instance (as future)
   */
  static Map<Path,Future<DartCodeChild>> _pathToDartCode = new Map();
  
  /*
   * Resolve a given hash checksum value into to content of the file. Because we 
   * know the file must have been read one time before (when created 
   * DartCodeChild object) we can use this cache when trying to send files to 
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
   * Resolve a URI into a [DartCodeChild] object. This method looks like the 
   * same as [DartCode.resolve] but the main difference is this method returns 
   * a [DartCodeChild] object when the [DartCode.resolve] method returns a 
   * [DartCode] object. The reason for this design is [DartCodeDb.resolve] is 
   * designed to be called recursive.
   * 
   * [useCache] should be set to false if some of the files has been changed
   * on the filesystem while the program has been running.
   */
  static Future<DartCodeChild> resolve(String uri, {bool useCache: true} ) {
    _log("Running DartCodeDb.resolve($uri, $useCache)");
    File sourceFile = new File(uri);
    
    Path path = new Path(uri);
    Path dir = path.directoryPath;
    Path packageDir = dir.append("packages");
    
    Future<DartCodeChild> dartCode;
    
    if (useCache) {
      dartCode = _pathToDartCode[path];
      
      if (dartCode != null) {
        return dartCode;
      }
    }

    dartCode = sourceFile.readAsBytes().then((List<int> bytes) {
      // Calculate SHA1 hashsum of the file.
      SHA1 sha1 = new SHA1();
      sha1.add(bytes);
      List<int> hash = sha1.close();
      
      /*
       *  Save the file content in cache (the file content is already loaded
       *  so we can insert the value directly in the future). Also map the
       *  hash with the path so we can get the path later if only knowing the
       *  hash value.
       */
      String hash = _hashListToString(hash);
      _sourceCache[hash] = new Future.value(bytes);
      _hashToPathCache[hash] = path;
      
      // Parse the file with the scanner and get dependencies
      Runes runes = (new String.fromCharCodes(bytes)).runes;
      Scanner scanner = new Scanner(runes);
      List<String> dependencies = scanner.getDependencies();
      
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
        Path fullFilePath;
        
        if (path.startsWith("package:")) {
          String pathString = path.substring("package:".length);
          fullFilePath = packageDir.append(pathString);
        } else {
          fullFilePath = dir.append(path);
        }
        _log("    Full path is: ${fullFilePath.toNativePath()}");
        
        return resolve(fullFilePath.toNativePath(), useCache:useCache);
      })).then((List<DartCodeChild> dependencies) {
        return new DartCodeChild(path.filename, path, hash, dependencies);
      });
    });
      
    _pathToDartCode[path] = dartCode;
    return dartCode;
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
      _pathToDartCode.clear();
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
        
        return contentFile.readAsBytes().then((List<int> fileContent) {
          SHA1 sha1 = new SHA1();
          sha1.add(fileContent);
          String newHash = _hashListToString(sha1.close());
          
          if (hash == newHash) {
            /* 
             * The file has not changed from last time we read it so we can use
             * it. If changeCache is true we are allowed to change the file
             * content cache and add the file content to this cache.
             */
            Future<List<int>> returnValue = Future.value(fileContent);
            if (changeCache) {
              _sourceCache[hash] = returnValue;  
            }
            return returnValue;
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
   * restriction it is not possible to use the Dart class [Link] on Windows 
   * systems. The purpose of the method is therefore to use different 
   * implementation on different systems.
   * 
   * On Windows we use hardlinks because they are possible to use without 
   * additional permissions. Dart do not support creating hardlinks so we call 
   * the mklink command from the Windows cmd instead.
   * 
   * On all other systems we use the [Link] class to create symlinks.
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
        if (!result.stderr.isEmpty) _err("     stderr: ${result.stderr}");
        
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
