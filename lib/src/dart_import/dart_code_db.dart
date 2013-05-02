part of distributed_dart;

class DartCodeDb {
  // Full path is the key
  Map<String,Future<DartCode>> _pathToDartCode = new Map<String,Future<DartCode>>();
  
  // Hash => Source code as List<int>
  Map<String,Future<List<int>>> _sourceCache = new Map<String,Future<List<int>>>();
  
  Future<DartCode> resolve(String uri, {bool useCache: true} ) {
    _log("Running resolve($uri, $useCache");
    File sourceFile = new File(uri);
    
    return sourceFile.fullPath().then((String fullPathString) {
      Path path = new Path(fullPathString);
      Path dir = path.directoryPath;
      Path packageDir = dir.append("packages");
      
      Future<DartCode> dartCode;
      
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
          
          return this.resolve(fullFilePath.toNativePath(), useCache:useCache);
        })).then((List<DartCode> dependencies) {
          return new DartCode(path.filename, path.toNativePath(), hash, dependencies);
        });
      });
      
      _pathToDartCode[path.toNativePath()] = dartCode;
      return dartCode;
    });
  }
  
  void clearCache() {
    _sourceCache.clear();
  }
  
  Future<List<int>> getSource(DartCode code) {
    String hash = code.dartCodeHashAsString;
    Future<List<int>> sourceCode = _sourceCache[hash];
    
    if (sourceCode == null) {
      sourceCode = new File(code.path).readAsBytes().then((List<int> content) {
        SHA1 sum = new SHA1();
        sum.add(content);
        
        if (_compareLists(sum.close(), code.fileHash) == false) {
          throw new FileChangedException();
        } else {
          return content;
        }
      });
      _sourceCache[hash] = sourceCode;
    }
    
    return sourceCode;
  }
  
  Future<List<int>> getSourceFromHash(String hash) {
    return _sourceCache[hash];
  }
  
  DartCode _resolve(String uri) {
    
  }
}

/*
import "dart:async";
import "dart:io";

class Cache {
  Map<String, Future<String>> cacheContent = new Map<String, Future<String>>();
  
  Future<String> getContent(String q) {
    if (!cacheContent.containsKey(q)) {
      cacheContent[q] = new Future<String>(() {
        File f = new File("bin/futuretest.dart");
        return f.readAsString();
      });
    }
    return cacheContent[q];
  }
}

void main() {
  Future<String> f = new Future.value("Farmen");
  
  f.then((t) => print(t));
  f.then((t) => print("Vi udskriver lige $t"));
  f.whenComplete(() => print("Future er færdig"));
  
  Cache c = new Cache();
  
  c.getContent("Hest").then((t) => print("1. $t og ${c.getContent("robåd").then((x) => print(x))}"));
  c.getContent("Hest").then((t) => print("2. $t og ${c.getContent("robåd").then((x) => print(x))}"));
  c.getContent("Hest").then((t) => print("3. $t"));
  
  c.getContent("robåd").then((x) => print("Test " + x));
  
  print("Hello, World!");
}
*/