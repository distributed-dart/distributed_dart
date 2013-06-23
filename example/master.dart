import 'dart:io';
import 'dart:isolate';
import "package:distributed_dart/distributed_dart.dart";

main(){
  logging = true;
  registerNode(new NodeAddress("127.0.0.1", 1234), true, "/tmp/master");
  var slave = new NodeAddress("127.0.0.1", 2345);
  var sp = spawnUriRemote("./hellodistributedworld.dart",slave);
  sp.send("hello my slave", port.toSendPort());
  port.receive((msg,reply) => print(msg));
}
