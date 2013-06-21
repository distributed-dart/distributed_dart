part of distributed_dart;

/// data on stream is encoded and sent to socket
outbox(Socket socket, Stream stream){
  stream
   .transform(new JsonEncoder())
   .transform(new StringEncoder())
   .transform(new ByteListEncoder())
   .listen(socket.add);
}

/// data on socket is passed to messagehandlers
inbox(Socket socket, _RequestHandlers rh){
  socket
    .transform(new ByteListDecoder())
    .transform(new StringDecoder())
    .transform(new JsonDecoder())
    .listen(rh.notify);
    //.listen(rh.runAll(new Network.fromSocket(socket)));
}

class Server {
  _RequestHandlers _requestHandlers;

  Server(){
    _requestHandlers = new _RequestHandlers();
    
    _requestHandlers.add(_NETWORK_FILE_HANDLER, _fileHandler);
    _requestHandlers.add(_NETWORK_FILE_REQUEST_HANDLER, _fileRequestHandler);
    _requestHandlers.add(_NETWORK_ISOLATE_DATA_HANDLER, _isolateDataHandler);
    _requestHandlers.add(_NETWORK_SPAWN_ISOLATE_HANDLER, _spawnIsolateHandler);
    
    ServerSocket.bind('0.0.0.0',12345).then(
        (serversocket) => serversocket.listen(
          (socket) => inbox(socket, _requestHandlers),
          onError: (e) => _err("ServerSocket Error: $e")));
  }
}

class Network {
  static Map<String, Network> connections = {};

  StreamController _sc = new StreamController();
  _RequestHandlers _requesthandlers = new _RequestHandlers();
  NodeAddress _node;

  Future connected;
  void send(String type, dynamic data) {
    _sc.add(_RequestHandlers.toMap(type, data));
  }

  /// Bind Streamtransformations on inputcomming and outgoing socket traffic
  _bindSocket(Socket s){
    outbox(s, _sc.stream);
    inbox(s, _requesthandlers);
  }

  /// Connect to [Network.node]
  _connect() {
    Socket.connect(_node.host,_node.port)
      .then(_bindSocket);
  }
}
