import 'dart:isolate';

main(){
  print('Hello, im waiting for data');
  port.receive((msg,reply){
     print(msg);
     print(msg.runtimeType);
     print(msg['message']);
//     var m = msg['message'];
//     print(m);
    /*  
     //var r = msg['reply'];
     var alist = msg['alist'];

     print("received message: $m");
     reply.send("reply from port in map: $m", null);
     alist.forEach(print);
     */
  });
}
