/*
 * Complete lolz :D
 * //!"##¤%¤#"&&%&%¤&¤""#¤1@£1£1£1
 * //\\//\\
 */
/// test
import "package:distributed_dart/distributed_dart.dart" as dist;
import "dart:io";
import "dart:crypto";
import "dart:json" as json;

void main() {
  File f = new File.fromPath(new Path("lib/distributed_dart.dart"));
  
  dist.logging = true;
  
  f.readAsBytes().then((List<int> filecontent) {
    // Beregn checksum
    SHA1 checksum = new SHA1();
    
    checksum.add(filecontent);
    List<int> checksumint = checksum.close();
    print("Checksum: $checksumint}");
    
    Runes r = (new String.fromCharCodes(filecontent)).runes;
    
//    r.forEach((int a) {
//      print(new String.fromCharCode(a));
//    });
    
    dist.Scanner s = new dist.Scanner(r);
    s.getDependencies().forEach((e) => print(e));
    //print(s.byteOffset);
    
    //db.getSource(new dist.DartCode("scanner_usage_example.dart", "lib/distributed_dart.dart", checksumint, [])).then((List<int> t) => t.forEach((int x) => print(new String.fromCharCode(x))));
    
    dist.DartCodeDb.resolveDartProgram("example/scanner_usage_example.dart", useCache:true).then((dist.DartProgram code) {
      print(code.path);
      
      code.dependencies.forEach((dist.FileNode object) {
        print(object.path);
      });
      
      String jcode = json.stringify(code);
      
      if (code.treeHash == new dist.DartProgram.fromJson(jcode).treeHash) {
        print("Hurra!");
      }
      
      code.createSpawnUriEnvironment().then((x) => print(x));
    });
  });
}