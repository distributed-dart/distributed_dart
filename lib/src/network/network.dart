part of distributed_dart;

// Exceptions ------------------------------------------------------------------
// Highlander Error (There can be, only one)
class IsolateNodeIsInitializedError implements Exception {
  final String msg;
  const IsolateNodeIsInitializedError([this.msg]);
  String toString() => msg == null ? 'UninitializedIsolateNodeError' : msg;
}

class UnInitializedIsolateNodeError implements Exception {
  final String msg;
  const UnInitializedIsolateNodeError([this.msg]);
  String toString() => msg == null ? 'UninitializedIsolateNodeError' : msg;
}


/**
  * Host identification, 
  * Must be initialized before a node can partake in a distributed application.
  */
class IsolateNode {
  final String host;
  final int port;

  static IsolateNode _singleton;

  /** Get [IsolateNode] for localhost
    * Throws UnInitializeIsolateNodeError if it has not been initialize with
    * [IsolateNode.initialize] 
    */
  static IsolateNode get localhost {
    if( _singleton == null) throw new UnInitializedIsolateNodeError();
    return _singleton;
  }

  String toString() => "$host:$port";

  /// create new objct from address
  IsolateNode(this.host, this.port);

  IsolateNode.fromSocket(Socket s):
    host = s.address.host,
    port = s.port;

  /// recreate object from map (json.parse)
  IsolateNode.fromMap(Map m):
    host = m['host'],
    port = m['port'];

  /// Initialize localhost
  factory IsolateNode.initialize(String host, int port){
    if( _singleton != null)
      throw new IsolateNodeIsInitializedError();

    _singleton = new IsolateNode(host,port);
    return _singleton;
  }
}

/// data on stream is encoded and sent to socket
outbox(Socket socket, Stream stream){
  stream
   .transform(new JsonEncoder())
   .transform(new StringEncoder())
   .transform(new ByteListEncoder())
   .listen(socket.add);
}

/// data on socket is passed to messagehandlers
inbox(Socket socket, RequestHandlers rh){
  socket
    .transform(new ByteListDecoder())
    .transform(new StringDecoder())
    .transform(new JsonDecoder())
    .listen(rh.notify);
    //.listen(rh.runAll(new Network.fromSocket(socket)));
}

class Server {
  RequestHandlers _requestHandlers = new RequestHandlers();

  Server(){
    ServerSocket.bind('0.0.0.0',12345).then(
        (serversocket) => serversocket.listen(
          (socket) => inbox(socket, _requestHandlers),
          onError: (e) => _err("ServerSocket Error: $e")));
  }
}

class Network {
  static Map<String, Network> connections = {};

  StreamController _sc = new StreamController();
  RequestHandlers _requesthandlers = new RequestHandlers();
  IsolateNode _node;

  Future connected;
  void send(String type, dynamic data) {
    _sc.add(RequestHandlers.toMap(type, data));
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
  
  static Network _lookupNode(IsolateNode node){
    var key = node.toString();
    if( connections.containsKey(key)){
      return connections[key];
    }
  }

  static Network _lookupSocket(Socket s){
    var node = new IsolateNode.fromSocket(s);
    var network = _lookupNode(node);
    return network;
  }

  Network._create();

  factory Network.fromNode(IsolateNode node){
    var net = _lookupNode(node);
    if( net == null ){
      net = new Network._create();
      net._node = node;
      net._connect();
      connections[net._node.toString()] = net;
    }
    return net;
  }
  
  factory Network.fromSocket(Socket s){
    var net = _lookupSocket(s);
    if( net == null ){
      net = new Network._create();
      net._node = new IsolateNode.fromSocket(s);
      net._bindSocket(s);
      connections[net._node.toString()] = net;
    }
    return net;
  }
}
