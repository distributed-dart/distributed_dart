library distributed_dart;
import 'dart:io';
import 'dart:async';
import 'dart:isolate';
import 'dart:json';
import 'dart:typeddata';

part 'src/dart_import/util/characters.dart';
//part 'src/dart_import/dart_code.dart';
//part 'src/dart_import/scanner.dart';

part 'src/network/network.dart';

// logging mechanism instad of print

/**
 * Set to true for enabling debug output from the distributed_dart library.
 * Default value is false.
 */
bool logging = false;

_log(String msg) =>  logging ? stdout.write("DIST_DART, log: ${msg}\n") : "";
_err(String msg) =>  logging ? stderr.write("DIST_DART, err: ${msg}\n") : "";
