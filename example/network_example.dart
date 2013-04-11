import 'package:distributed_dart/distributed_dart.dart';
import 'dart:math';


/** when sending several small messages, the socket interface automaticly
  * concatinates the data into a single message.
  * this module json encodes the message, and adds a header so that 
  * it can be restored as it was on the receiving side.
  *
  * conversly, when sending large messages, the socket interface will
  * split them into more than one. This is also remedied in this module.
  */
main(){
  Logging = true;
  startServer();
  var remote = spawnRemote("not_implemented");

  var r = new Random();
  var huge_random_list = new List.generate(
      100000, (i) => r.nextInt(100000000));


  var unicode_string = "æøå ÆØÅ \u2230 \u2231 \u2232";
  remote.add(unicode_string);

  remote.add(huge_random_list);
}
