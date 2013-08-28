import 'dart:io';
import 'dart:isolate';
import "package:distributed_dart/distributed_dart.dart";

main(){
  logging = true;
  if(new Options().arguments.length > 0)
    logging = false;

  registerNode(new NodeAddress("127.0.0.1", 1234), true);
  var slave1 = new NodeAddress("127.0.0.1", 1001);
  var slave2 = new NodeAddress("127.0.0.1", 1002);
  
  var remote1 = spawnUriRemote("./hellodistributedworld.dart",slave1);
  var remote2 = spawnUriRemote("./hellodistributedworld.dart",slave2);
  
  remote1.send(remote2);
  remote2.send(remote1);
}
