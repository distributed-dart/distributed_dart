import 'dart:isolate';

main(){
  print('Hello, im waiting for data');
  port.receive((msg,reply) => print(msg));
}
