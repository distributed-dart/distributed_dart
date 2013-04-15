import "package:distributed_dart/distributed_dart.dart";
import "dart:io";
import "dart:crypto";

void main() {
  File f = new File.fromPath(new Path("example/scanner_usage_example.dart"));
  
  logging = true;
  
  f.readAsBytes().then((List<int> filecontent) {
    // Beregn checksum
    SHA1 checksum = new SHA1();
    
    checksum.add(filecontent);
    print("Checksum: ${checksum.close()}");
    
    Runes r = (new String.fromCharCodes(filecontent)).runes;
    
    r.forEach((int a) {
      print(new String.fromCharCode(a));
    });
    
    Scanner s = new Scanner(r);
    s.scan();
    s.paths.forEach((e) => print(e));
    print(s.byteOffset);
  });
}