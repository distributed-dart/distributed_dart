import 'dart:isolate';

main(){
  port.receive((msg,reply){
      print("hellodistributedworld received: ${msg['msg']}");
      msg['reply'].send("OK: ${msg['msg']}");
  });
}
