import 'dart:isolate';
import "package:distributed_dart/distributed_dart.dart" as dist;

void main() {
  dist.IsolateCommunication test = new dist.IsolateCommunication();
  
  print(test.scanAndReplaceObject("test"));
}