part of distributed_dart;

class HostLookup {
  static Map whereIsIsolate(String id){
    return { 'host': '127.0.0.1', 'port' : 12345 };
  }

  static Map whereIsHost(String hostname){
    return { 'host': '127.0.0.1', 'port' : 12345 };
  }
}

class Server {
  MessageObserver messageHandlers = new MessageObserver();
  
  Server(){
    ServerSocket.bind('0.0.0.0',12345).then(
        (serversocket) => serversocket.listen(
          _onConnection,
          onError: (e) => _err("ServerSocket Error: $e")));
  }

  addMessageHandler(MessageHandler h) => messageHandlers.append(h);

  _onConnection(Socket client){
    client
      .transform(new ZlibInflater())
      .transform(new ByteListDecoder())
      .transform(new StringDecoder())
      .transform(new JsonDecoder())
      .listen(messageHandlers.listen);
  }

}

class Network {
  Socket _socket;
  Completer _socketReady = new Completer();
  static Server server = new Server();
  static Map<String, Network> _instances = {};

  factory Network(String id){
    var key = "${addr['host']}:${addr['port']}";
    if(! _instances.containsKey(key)){
      _instances[key] = new Network._connect(addr['host'], addr['port']);
    }
    return _instances[key];
  }

  Network._connect(host,port){
    Socket.connect(host,port)
      .then((s) => _socket = s)
      .then((_) => _socketReady.complete(true));
  }

  void send(Stream data){
    stream
      .transform(new JsonEncoder())
      .transform(new StringEncoder())
      .transform(new ByteListEncoder())
      .transform(new ZlibDeflater())
      .listen((d) => _socket.add(d))
      .pause(_socketReady.future);
  }
}

