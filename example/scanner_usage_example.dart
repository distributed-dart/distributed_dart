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
    
    // DartCode(this.name, this.path, this.hash, this.dependencies);
    dist.DartCode a = new dist.DartCode("Name a", "/usr/bin", [ 1, 2, 3], null);
    dist.DartCode b = new dist.DartCode("Name b", "/usr/bin", [ 1, 2, 3], [a]);
    dist.DartCode c = new dist.DartCode("Name c", "/usr/bin", [ 1, 2, 3], [b]);
    dist.DartCode d = new dist.DartCode("Name d", "/usr/bin", [ 1, 2, 3], null);
    dist.DartCode e = new dist.DartCode("Name e", "/usr/bin", [ 1, 2, 3], [d, c]);
    
    print(json.stringify(e));
    
    dist.DartCode k = new dist.DartCode.fromJson(json.stringify(e));
    
    k.dependencies.forEach((dist.DartCode x) => print(x.name));
    print(k.fileHash);
    print(k.dartCodeHash);
    print(k.dartCodeHashAsString);
    print(f.fullPathSync());
    
    dist.DartCodeDb db = new dist.DartCodeDb();
    //db.getSource(new dist.DartCode("scanner_usage_example.dart", "lib/distributed_dart.dart", checksumint, [])).then((List<int> t) => t.forEach((int x) => print(new String.fromCharCode(x))));
    
    db.resolve("example/scanner_usage_example.dart", useCache:true).then((dist.DartCode code) {
      code.dependencies.forEach((dist.DartCode object) {
        print(object.path);
        object.dependencies.forEach((dist.DartCode x) => print(x.fileHashAsString));
      });
    });
    
  });
}