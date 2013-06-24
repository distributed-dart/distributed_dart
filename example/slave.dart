import 'dart:io';
import "package:distributed_dart/distributed_dart.dart";

main(){
  logging = true;
  if(new Options().arguments.length > 0)
    logging = false;

  registerNode(new NodeAddress("127.0.0.1", 2345), true);
}
