part of distributed_dart;

class Host {
  final String addr;
  final int port;
  String toString() => "$addr:$port";
  Host(this.addr, this.port);
}

class HostLookup {
  static Host isolateId(IsolateId id) => new Host('127.0.0.1', 12345);
  static Host hostname(String name) => new Host('127.0.0.1', 12345);
}

class Server {
  var handlerList = new RequestHandlerList();

  Server(){
    ServerSocket.bind('0.0.0.0',12345).then(
        (serversocket) => serversocket.listen(
          _onConnection,
          onError: (e) => _err("ServerSocket Error: $e")));
  }

  addHandler(int type, RequestHandler h) => handlerList.add(type,h);

  _onConnection(Socket client){
    client
      .transform(new ZLibInflater())
      .transform(new ByteListDecoder())
      .transform(new StringDecoder())
      .transform(new JsonDecoder())
      .listen(handlerList.runAll);
  }
}

class FileServer {
  FileServer(DartCode code);
}

class Network {
  Socket _socket;
  Completer _socketReady = new Completer();
  static Server server = new Server();
  static Map<String, Network> _connections = {};

  // lookup network connection for specific isolate id
  factory Network.isolateId(IsolateId id){
    Host host = HostLookup.isolateId(id);
    if( ! _connections.containsKey("$host")) {
      _connections["$host"] = new Network._connect(host);
    }
    return _connections["$host"];
  }

  // connect to remote host, completes _socketReady on success
  Network._connect(Host host){
    Socket.connect(host.addr,host.port)
      .then((s) => _socket = s)
      .then((_) => _socketReady.complete(true));
  }

  // encodes and sends data to network connection
  // buffers data on stream until the sockets is ready
  void send(Stream datastream){
    datastream
      .transform(new JsonEncoder())
      .transform(new StringEncoder())
      .transform(new ByteListEncoder())
      .transform(new ZLibDeflater())
      .listen((d) => _socket.add(d))
      .pause(_socketReady.future);
  }
}

