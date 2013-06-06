library distributed_dart_test;
import 'package:unittest/unittest.dart';
import 'package:unittest/vm_config.dart';
import 'package:distributed_dart/distributed_dart.dart' as dist;

part 'scanner_test.dart';
part 'network_test.dart';

void main() {
  useVMConfiguration();
  dist.logging = true;
  
  scanner_test();
  network_test();
}