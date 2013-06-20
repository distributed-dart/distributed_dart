part of distributed_dart;

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
