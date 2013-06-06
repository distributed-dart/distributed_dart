part of distributed_dart;

/**
  * Sendport Proxy
  * Reference to a specific [LocalIsolate].
  * To send a [SendPort] to a remote host, it must be wrapped in a
  * [LocalIsolate] and sent as a [RemoteSendPort]
  */
class RemoteSendPort {
  final IsolateId id;
  final IsolateNode node;

  RemoteSendPort(this.id): node = IsolateNode.localhost;

  RemoteSendPort.fromMap(Map m):
    id = new IsolateId.fromMap(m['id']),
    node = new IsolateNode.fromMap(m['node']);

  void send(dynamic data, reply){
    var request = null; // TODO: new IsolateDataRequest(data)
    new Network.fromNode(node).send(request);
  }
  
  Future call(dynamic data){
    var c = new Completer();
    //new Network.fromNode(node).send(new IsolateDataRequest());
    return c.future;
  }

  /// stream interface
  void add(dynamic data){
    send(data,null);
  }
}

/**
  * unique ID to distinguish isolates
  */
class IsolateId {
  static int nextid = 0;

  final int id;
  final int timestamp;
  final int port;
  final String host;

  IsolateId():
   id = nextid++,
   timestamp = new DateTime.now().millisecondsSinceEpoch,
   port = IsolateNode.localhost.port,
   host = IsolateNode.localhost.host;

  IsolateId.fromMap(Map m):
    id = m['id'], 
    timestamp = m['timestamp'], 
    port = m['port'],
    host = m['host'];
  
  Map toJson(){
   var obj = { 
     'id' : id,
     'timestamp': timestamp,
     'port': port, 
     'host' : host 
   }; 
   return obj;
  }

  String toString() => "$host:$id:$timestamp";
}

/**
  * Lookup table, contains reference to all physical isolates spawned on the
  * current Node.
  * 
  * The table contains a mapping between an [IsolateId] and a [SendPort]
  * [SendPort]'s can be created manually, and bound to a [LocalIsolate]
  * object, or it can be created directly in via a [LocalIsolate] constructor.
  */
class LocalIsolate{
  final IsolateId id = new IsolateId();
  final SendPort sendport;
  
  /// [LocalIsolate] lookup table, key is (string) IsolateId
  static Map<String, LocalIsolate> _isolatemap = {};
  RemoteSendPort toRemoteSendPort() => new RemoteSendPort(id);

  /** 
    * Search for [LocalIsolate] instance
    * returns null if isolate does not exist.
    */
  static LocalIsolate Lookup(IsolateId id){
    var key = id.toString();
    if( _isolatemap.containsKey(key))
      return _isolatemap[key];
  }

  /// spawn a new isolate
  factory LocalIsolate.spawn(String uri){
    var sp = spawnUri(uri);
    return new LocalIsolate.fromSendPort(sp); 
  }

  /// bind a new sendport to the [LocalIsolate] lookup table
  LocalIsolate.fromSendPort(this.sendport){
    _isolatemap[id.toString()] = this; 
  }
}

/**
  * Mapping between [IsolateId] and [RemoteSendPort]
  */
class RemoteIsolate {
  /// map: (string) IsolateId -> RemoteSendPort
  static Map<String,RemoteSendPort> _remoteports = {};

  static RemoteSendPort Lookup(IsolateId id) {
    if( _remoteports.containsKey(id.toString()))
        return _remoteports[id.toString()];
  }

  static Future<IsolateId> Spawn(String uri){
    Future<FileNode> dc = DartCodeDb.resolveDartProgram(uri);
    return new Future.value(new IsolateId()); // TODO: get from remote 
  }
}


// PUBLIC API //////////////////////////////////////////////////////////////////////
/**
  * Creates and spawns an isolate whose code is available at uri. 
  * The isolate is spawned on a remote node available in the distributed network.
  * Returns an IsolateSink feeding into the remote isolate stream
  */
IsolateSink streamSpawnUriRemote(String uri){

  // incomming data is buffered in the streamcontroller until the network 
  // connection is established, which allows us to return a sink immediatly, 
  // and setup network async
  var sc = new StreamController();
  
  // setup stream listener to network object.
  bindNetwork(IsolateId id){
    sc.stream
      .transform(IsolateDataRequest.transform(id))
      .listen((d) => RemoteIsolate.Lookup(id).send(d,null));
  }

  // send spawn request, and bind stream to network object when done
  RemoteIsolate.Spawn(uri).then(bindNetwork);
  return sc.sink;
}

/**
  * Creates and spawns an isolate whose code is available at uri. 
  * The isolate is spawned on a remote node available in the distributed network.
  * Returns a sendport which is linked to the remote isolate ReceivePort
  */
SendPort spawnUriRemote(String uri){
  var sink = streamSpawnUriRemote(uri);
  var rp = new ReceivePort();
  rp.receive((data,_) => sink.add(data));
  return port.toSendPort();
}

