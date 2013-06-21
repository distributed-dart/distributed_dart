part of distributed_dart;

class Network {
  
  /// only one connection for each remote host, shared by all
  static Map<NodeAddress, Network> _connections = {};

  /*
   *  acts as a buffer for incomming data
   *  a listening socket is not registerd before a connection has been made
   *  but data can be added to the sink anyway 
   */
  StreamController _sc = new StreamController();
  
  NodeAddress _node;

  void send(String type, dynamic data) {
    _sc.sink.add(_RequestHandler.annotateData(type, data));
  }

  /// Connect to remote host
  Network._connect(this._node) {
    Socket.connect(_node.host,_node.port)
      .then((socket){
        _incomming(socket);
        _outgoing(socket);
      });
  }
  
  /// return a shared network object for each unique 
  factory Network(NodeAddress node){
    if(! _connections.containsKey(node)){
      var network = new Network._connect(_node);
      _connections[node] = network;
    }
    return _connections[node];
  }
  
  static void initServer(){   
    ServerSocket.bind('0.0.0.0',12345).then(
        (serversocket) => serversocket.listen(
          (socket) => _incomming(socket),
          onError: (e) => _err("ServerSocket Error: $e")));
  }
  
  /// outging data is encoded, and sent via the shared socket
  _outgoing(Socket socket){
    _sc.stream
    .transform(new JsonEncoder())
    .transform(new StringEncoder())
    .transform(new ByteListEncoder())
    .listen(socket.add);
  }

  /// all incomming data will be handled by the [_RequestHandler]
  static _incomming(Socket socket){
    socket
    .transform(new ByteListDecoder())
    .transform(new StringDecoder())
    .transform(new JsonDecoder())
    .listen(_RequestHandler.notify);
  }
  
}
