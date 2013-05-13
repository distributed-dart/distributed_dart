part of distributed_dart;

class DartCodeDb {
  // Full path is the key
  static Map<String,Future<DartCodeChild>> _pathToDartCode = new Map();
  
  // Hash => Source code as List<int>
  static Map<String,Future<List<int>>> _sourceCache = new Map();
  
  static Future<DartCodeChild> resolve(String uri, {bool useCache: true} ) {
    _log("Running DartCodeDb.resolve($uri, $useCache)");
    File sourceFile = new File(uri);
    
    Path path = new Path(uri);
    Path dir = path.directoryPath;
    Path packageDir = dir.append("packages");
    
    Future<DartCodeChild> dartCode;
    
    if (useCache) {
      dartCode = _pathToDartCode[path.toNativePath()];
      
      if (dartCode != null) {
        return dartCode;
      }
    }

    dartCode = sourceFile.readAsBytes().then((List<int> bytes) {
      // Calculate SHA1 hashsum of the file.
      SHA1 sha1 = new SHA1();
      sha1.add(bytes);
      List<int> hash = sha1.close();
      
      // Save the file content in cache (the file content is already loaded
      // so we can insert the value directly in the future.
      _sourceCache[_hashListToString(hash)] = new Future.value(bytes);
      
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
      
    _pathToDartCode[path.toNativePath()] = dartCode;
    return dartCode;
  }
  
  static void clearCache() {
    _sourceCache.clear();
  }
  
  static Future<List<int>> getSource(DartCode code) {
    String hash = code.fileHash;
    Future<List<int>> sourceCode = _sourceCache[hash];
    
    if (sourceCode == null) {
      File sourceFile = new File.fromPath(code.path);
      sourceCode = sourceFile.readAsBytes().then((List<int> content) {
        SHA1 sum = new SHA1();
        sum.add(content);
        
        if (_compareLists(sum.close(), code.fileHashAsList) == false) {
          throw new FileChangedException();
        } else {
          return content;
        }
      });
      _sourceCache[hash] = sourceCode;
    }
    
    return sourceCode;
  }
  
  static Future<List<int>> getSourceFromHash(String hash) {
    return _sourceCache[hash];
  }
  
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
      
      StringBuffer sb = new StringBuffer("");
      for (int a = 0; a < source.segments().length; a++) {
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
