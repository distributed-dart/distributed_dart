import 'dart:isolate';
import "package:distributed_dart/distributed_dart.dart";

main(){
  port.receive((msg,reply){
      print("hellodistributedworld received: ${msg['msg']}");
      msg['reply'].send("OK: ${msg['msg']}");
  });
}
