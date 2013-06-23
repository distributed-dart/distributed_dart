import 'dart:io';
import "package:distributed_dart/distributed_dart.dart";

main(){
  logging = true;
  registerNode(new NodeAddress("127.0.0.1", 2345), true);
}
