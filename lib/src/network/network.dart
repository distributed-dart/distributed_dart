part of distributed_dart;

/// data on stream is encoded and sent to socket
_outgoing(Stream stream, Socket socket){
  stream
   .transform(new JsonEncoder())
   .transform(new StringEncoder())
   .transform(new ByteListEncoder())
   .transform(new ZLibDeflater());
   .listen(socket.add);
}

/// data on socket is passed to messagehandlers
_incomming(Socket socket, messagehandlers){
  socket
    .transform(new ZLibInflater())
    .transform(new ByteListDecoder())
    .transform(new StringDecoder())
    .transform(new JsonDecoder())
    .listen(messagehandlers.runAll);
}

class Server {
  RequestHandlers _handlers = new RequestHandlers();

  Server(){
    ServerSocket.bind('0.0.0.0',12345).then(
        (serversocket) => serversocket.listen(
          (socket) => _incomming(socket, handlerList),
          onError: (e) => _err("ServerSocket Error: $e")));
  }
}

class Network {
  StreamController _sc = new StreamController();
  RequestHandlers _handlers = new RequestHandlers();
  InternetAddress _host;

  void send(dynamic data) => _sc.add(data);

  _bindSocket(Socket s){
    _outgoing(s);
    _incomming(s);
  }

  Future _connect() => Socket.connect(_host).then(_bindSocket);

  Network._(this._host){
    _connect();
  }

  factory Network.isolateId(IsolateId id){ }
}


fisk(){

  var handlers =new RequestHandlerList();
  handlers.add(new SpawnIsolateRequest());
  handlers.add(new IsolateDataRequest());
}
