library distributed_dart;
import 'dart:io';
import 'dart:async';
import 'dart:isolate';
import 'dart:json' as json;
import 'dart:typed_data';
import 'dart:crypto';

part 'src/dart_import/util/characters.dart';
part 'src/dart_import/util/tools.dart';
part 'src/dart_import/dart_code.dart';
part 'src/dart_import/dart_code_child.dart';
part 'src/dart_import/dart_code_db.dart';
part 'src/dart_import/scanner.dart';
part 'src/dart_import/exceptions.dart';

part 'src/network/isolates.dart';
part 'src/network/network.dart';
part 'src/network/placeholders.dart';
part 'src/network/requesthandler.dart';
part 'src/network/streamtransformations.dart';

bool _workDirInUse = false;
String _workDir = ".distribued_dart_data/";

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
