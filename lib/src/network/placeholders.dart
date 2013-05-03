part of distributed_dart;

/*
class DartCode {
  DartCode();
  DartCode.fromMap(Map dc);
}
*/

class HostLookup {
  static Host isolateId(IsolateId id) => new Host('127.0.0.1', 12345);
  static Host hostname(String name) => new Host('127.0.0.1', 12345);
}

class FileServer {
  FileServer(DartCode code);
}

