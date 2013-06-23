import 'dart:io';
import 'dart:isolate';
import "package:distributed_dart/distributed_dart.dart";

main(){
  logging = true;
  registerNode(new NodeAddress("127.0.0.1", 1234), true, "/tmp/master");
  var slave = new NodeAddress("127.0.0.1", 2345);
  var sp = spawnUriRemote("./hellodistributedworld.dart",slave);

  var anotherport = new ReceivePort();
  anotherport.receive((msg,reply) => print("on another port: $msg"));
  port.receive((msg,reply) => print(msg));

  var data = { 
    'message' : 'hello distributed dart', 
    'reply' : anotherport.toSendPort(),
    'alist' : [ 1 , 23, 4, 'heste' ]
  };


  sp.send("hello my slave", port.toSendPort());
  sp.send(data, port.toSendPort());

}
