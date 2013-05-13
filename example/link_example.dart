import "dart:io";
import "dart:async";
import "package:distributed_dart/distributed_dart.dart" as dist;

void main() {
  Path destination = new Path("example/link_example.link.dart");
  Path source = new Path("example/link_example.dart");
  
  dist.DartCodeDb.createLink(source, destination).then((_) {
    print("Try delete link.");
    new File.fromPath(destination).delete().then((_)=>print("Link deleted"));
  });
}
