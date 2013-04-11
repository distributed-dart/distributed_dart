library distributed_dart;
import 'dart:io';
import 'dart:async';
import 'dart:isolate';
import 'dart:json';
import 'dart:typeddata';

part 'src/dart_import/util/characters.dart';
part 'src/network/network.dart';


// logging mechanism instad of print
bool _logging = false;
set Logging  (bool value) => _logging = value;
_log(String msg) =>  _logging ? stdout.write("DIST_DART, log: ${msg}\n") : "";
_err(String msg) =>  _logging ? stderr.write("DIST_DART, err: ${msg}\n") : "";


