import 'dart:isolate';
import "package:distributed_dart/distributed_dart.dart";

main(){
  port.receive((msg,reply) {
    if (msg is String) {
      print(msg);
    } else {
      msg.send("Hello");  
    }
  });
}
