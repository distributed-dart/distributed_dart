library distributed_dart;

// Dart API
import 'dart:io';
import 'dart:async';
import 'dart:isolate';
import 'dart:json' as json;
import 'dart:typed_data';

// Included packages
import 'package:crypto/crypto.dart';

// Global library stuff used in different parts
part 'src/exceptions.dart';
part 'src/errors.dart';

// Import files part
part 'src/dart_import/util/characters.dart';
part 'src/dart_import/util/tools.dart';
part 'src/dart_import/tree/file_node.dart';
part 'src/dart_import/tree/dependency_node.dart';
part 'src/dart_import/dart_program.dart';
part 'src/dart_import/dart_code_db.dart';
part 'src/dart_import/request_bundle.dart';
part 'src/dart_import/scanner.dart';

// Isolate control
part 'src/isolates/isolates.dart';
part 'src/isolates/isolaterequests.dart';

// Network system for communication between nodes
part 'src/network/network.dart';
part 'src/network/requesthandler.dart';
part 'src/network/streamtransformations.dart';

// Network handlers to handle received network packages
part 'src/network/handler/filehandler.dart';
part 'src/network/handler/filerequesthandler.dart';
part 'src/network/handler/isolatedatahandler.dart';
part 'src/network/handler/spawnisolatehandler.dart';

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
