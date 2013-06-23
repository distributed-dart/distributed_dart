import 'dart:isolate';

main(){
  port.receive((msg,reply){
      print("received: $msg");
      reply.send("OK: $msg");
  });
}
