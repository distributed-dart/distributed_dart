import 'dart:io';
import 'dart:isolate';
import "package:distributed_dart/distributed_dart.dart";

main(){
  logging = true;
  registerNode(new NodeAddress("127.0.0.1", 1234), true);
  var slave = new NodeAddress("127.0.0.1", 2345);
  var remote = spawnUriRemote("./hellodistributedworld.dart",slave);
  //var local = spawnUri("./hellodistributedworld.dart",slave);
  port.receive((msg,reply) => print(msg));
  remote.send("hello remote world",port.toSendPort());
}
