library distributed_dart;
import 'dart:io';
import 'dart:async';
import 'dart:isolate';
import 'dart:json' as json;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

part 'src/exceptions.dart';
part 'src/errors.dart';

part 'src/dart_import/util/characters.dart';
part 'src/dart_import/util/tools.dart';
part 'src/dart_import/tree/file_node.dart';
part 'src/dart_import/tree/dependency_node.dart';
part 'src/dart_import/dart_program.dart';
part 'src/dart_import/dart_code_db.dart';
part 'src/dart_import/request_bundle.dart';
part 'src/dart_import/scanner.dart';

part 'src/isolates/isolates.dart';
part 'src/isolates/isolaterequests.dart';

part 'src/network/network.dart';
part 'src/network/requesthandler.dart';
part 'src/network/streamtransformations.dart';

bool _workDirInUse = false;
String _workDir = ".distributed_dart_data/";

set workDir(String path) {
  if (_workDirInUse) {
    String e = "Not allowed to set workDir variable after it is used.";
    throw new WorkDirInUseException(e);
  }
  _workDir = path;
}

String get workDir {
  _workDirInUse = true;
  return _workDir;
}

/**
 * Set to [true] for enabling debug output from the distributed_dart library.
 * Default value is [false].
 */
bool logging = false;

/**
 * Send standard log message to standard output. Is only showed if the 
 * [logging] variable is [true].
 */
_log(var msg) => logging ? stdout.writeln("DIST_DART, log: ${msg}") : "";

/**
 * Send error log message to standard error output. Is only showed if the 
 * [logging] variable is [true].
 */
_err(var msg) => logging ? stderr.writeln("DIST_DART, err: ${msg}") : "";
