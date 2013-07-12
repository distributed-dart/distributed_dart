part of distributed_dart;

class _Network {
  
  /// only one connection for each remote host, shared by all
  static Map<NodeAddress, _Network> _connections = new Map();

  /*
   *  acts as a buffer for incomming data
   *  a listening socket is not registerd before a connection has been made
   *  but data can be added to the sink anyway 
   */
  StreamController _sc = new StreamController();
  
  NodeAddress _node;

  void send(String type, dynamic data) {
    _log("sending $type to ${_node}");
    _sc.sink.add(_RequestHandler.annotateData(type, data));
  }

  /// Connect to remote host
  _Network._connect(this._node) {
    Socket.connect(_node.host,_node.port)
      .then((socket){
        _log("connected to ${_node}");
        _incomming(socket);
        _outgoing(socket);
      })
      .catchError(_err);
  }
  
  /// return a shared network object for each unique 
  factory _Network(NodeAddress node){
    if(! _connections.containsKey(node)){
      var network = new _Network._connect(node);
      _connections[node] = network;
    }
    return _connections[node];
  }
  
  static void _initServer(){
    var host = NodeAddress._localhost.host;
    var port = NodeAddress._localhost.port;
    ServerSocket.bind(host,port)
      .then((serversocket){
        serversocket.listen((socket) => _incomming(socket),
            onError: (e) => _err("ServerSocket Error: $e"));
        _log("Listening on $host:$port");
      });

  }
  
  /// outging data is encoded, and sent via the shared socket
  _outgoing(Socket socket){
    _sc.stream
    .transform(new _JsonEncoder())
    .transform(new _JsonLogger("outgoing json"))
    .transform(new StringEncoder())
//    .transform(new _Compress()) <- Very bad performance
    .transform(new _ByteListEncoder())
    .listen(socket.add);
  }

  /// all incomming data will be handled by the [_RequestHandler]
  static _incomming(Socket socket){
    _log("new incomming connection");
    socket
    .transform(new _ByteListDecoder())
//    .transform(new _Extract()) <- Very bad performance
    .transform(new StringDecoder())
    .transform(new _JsonLogger("incomming json"))
    .transform(new _JsonDecoder())
    .listen(_RequestHandler.notify);
  }
}

class _JsonLogger extends StreamEventTransformer<String, String> {
  final String name;
  
  _JsonLogger(this.name);
  
  void handleData(String data, EventSink<String> sink){
    _log("$name: $data");
    sink.add(data);
  }
}

class _Compress extends StreamEventTransformer<List<int>, List<int>> {
  void handleData(List<int> data, EventSink<List<int>> sink) {
    List<int> _temp = new List();
    Stream<List<int>> stream = new Stream.fromFuture(new Future.value(data));
    stream.transform(new ZLibDeflater()).listen((List<int> compressedData) {
      _temp.addAll(compressedData);
    }, onDone: () {
      _log("data size before/after Compress: ${data.length}/${_temp.length} bytes");
      sink.add(_temp);
    });
  }
}

class _Extract extends StreamEventTransformer<List<int>, List<int>> {
  void handleData(List<int> data, EventSink<List<int>> sink) {
    List<int> _temp = new List();
    Stream<List<int>> stream = new Stream.fromFuture(new Future.value(data));
    stream.transform(new ZLibInflater()).listen((List<int> extractedData) {
      _temp.addAll(extractedData);
    }, onDone: () {
      _log("data size before/after Extract: ${data.length}/${_temp.length} bytes");
      sink.add(_temp);
    });
  }
}
