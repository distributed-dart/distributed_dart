import 'dart:io';
import "package:distributed_dart/distributed_dart.dart";

main(){
  
  logging = true;
  
  var opt = new Options();
  var name = opt.arguments[0];
  var port = int.parse(opt.arguments[1],radix:10);

  registerNode(new NodeAddress("127.0.0.1", port), true, "/tmp/$name");
  
  if(opt.arguments.length > 3){
    var target = new NodeAddress(
        opt.arguments[2],
        int.parse(opt.arguments[3],radix:10));
    
    var n = new Network(target);
    n.send("spawn_isolate", "I CAN HAZ ISOLATE???");
  }
}
