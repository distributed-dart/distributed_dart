/*
 * Complete lolz :D
 * //!"##¤%¤#"&&%&%¤&¤""#¤1@£1£1£1
 * //\\//\\
 */
/// test
import "package:distributed_dart/distributed_dart.dart" as dist;
import "dart:io";
import "dart:crypto";

void main() {
  File f = new File.fromPath(new Path("lib/distributed_dart.dart"));
  
  dist.logging = true;
  
  f.readAsBytes().then((List<int> filecontent) {
    // Beregn checksum
    SHA1 checksum = new SHA1();
    
    checksum.add(filecontent);
    print("Checksum: ${checksum.close()}");
    
    Runes r = (new String.fromCharCodes(filecontent)).runes;
    
//    r.forEach((int a) {
//      print(new String.fromCharCode(a));
//    });
    
    dist.Scanner s = new dist.Scanner(r);
    s.scan();
    s.paths.forEach((e) => print(e));
    //print(s.byteOffset);
  });
}