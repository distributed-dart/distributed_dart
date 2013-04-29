library distributed_dart;
import 'dart:io';
import 'dart:async';
import 'dart:isolate';
import 'dart:json' as json;
import 'dart:typed_data';
import 'dart:crypto';

part 'src/dart_import/util/characters.dart';
part 'src/dart_import/dart_code.dart';
part 'src/dart_import/dart_code_db.dart';
part 'src/dart_import/scanner.dart';

part 'src/network/network.dart';

// logging mechanism instad of print

/**
 * Set to true for enabling debug output from the distributed_dart library.
 * Default value is false.
 */
bool logging = false;

_log(var msg) => logging ? stdout.writeln("DIST_DART, log: ${msg}") : "";
_err(var msg) => logging ? stderr.writeln("DIST_DART, err: ${msg}") : "";
