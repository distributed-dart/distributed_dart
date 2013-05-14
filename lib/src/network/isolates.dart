part of distributed_dart;
/**
  * Lookup table, contains mapping between [IsolateId] and [SendPort]
  */
class LocalIsolate{

  final IsolateId id = new IsolateId();
  final SendPort sendport;
  
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

  /**
    * spawn a new isolate
    */
  factory LocalIsolate.Spawn(String uri){
    var sp = spawnUri(uri);
    return new LocalIsolate.BindSendPort(sp); 
  }

  /**
    * Bind a new sendport to the [LocalIsolate] lookup table
    */
  LocalIsolate.BindSendPort(this.sendport){
    _isolatemap[id.toString()] = this; 
  }
}

class RemoteSendPort {
  final IsolateId id;
  final IsolateNode node = IsolateNode.localhost;

  RemoteSendPort(this.id);

  void send(dynamic data, reply){
    //TODO: 
  }
  
  Future call(dynamic data){
    //TODO:
  }

  void add(dynamic data){
    // TODO:
  }
}

/// unique ID
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
  * Setup communication with remote node, and send spawn request
  */
class RemoteIsolate {
  static Map<String,Network> _isolatemap;
  static Network Lookup(IsolateId id) => _isolatemap[id.toString()];
  static Future<IsolateId> Spawn(String uri){
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
      .listen(RemoteIsolate.Lookup(id).send);
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

