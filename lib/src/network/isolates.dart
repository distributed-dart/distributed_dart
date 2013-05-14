part of distributed_dart;

// Request to spawn new isolate
class SpawnIsolateRequest implements Request {
  const int type = RequestType.SpawnIsolate;
  final DartCode code;
  final IsolateId id;

  SpawnIsolateRequest.dummy();
  SpawnIsolateRequest(this.code);

  SpawnIsolateRequest.fromMap(Map data):
    code = new DartCode.fromMap(data['code']),
    id = new IsolateId.fromMap(data['id']);
  
  toJson() => { 'type' : type,'code' : code, 'id' : id};

  // 1.a) lookup code
  // 1.b) fetch code if missing
  // 2) spawn local isolate
  void _requestHandler(Map request, Network reply){
    
    spawn(uri){
      var remoteisolate = new RemoteReceivePort(id,uri);
      var response = new SpawnIsolateOk(remoteisolate.toRemoteSendPort());
      reply.send(response);
    }

    // TODO: add error handler
    new SpawnIsolateRequest.fromMap(request).code.geturi.then(spawn); 
  }
}

class SpawnIsolateResponse implements Request {
  const int type = RequestType.SpawnIsolateResponse;
  final RemoteSendPort port;
  SpawnIsolateResponse(this.port);
  SpawnIsolateResponse.fromMap(Map obj): port = obj['port'];

  void _requestHandler(Map request, Network reply){
    // 
  }
}

// metadata for data sent to isolate
class IsolateDataRequest implements Request {
  const int type = RequestType.IsolateData;
  IsolateId id;
  IsolateId reply;
  dynamic data;

  IsolateDataRequest._dummy();
  IsolateDataRequest(this.id, this.data):
  IsolateDataRequest._fromMap(Map m):
    this.id = m['id'],
    this.data = m['data'];

  toJson() => { 'type': type, 'id' : id, 'data' : data };

  // StreamTransformer to wrap input data in a IsolateDataRequest
  static StreamTransformer transform(id){
    return new StreamTransformer(
       handleData: (data, sink) => sink.add(new IsolateDataRequest(id, data))
       );
  }

  // request handler implementation for an IsolateDataRequest
  // 1. lookup remote sendport in sendport db
  // 2. send data to remote sendport

  void _requestHandler(Map req, Network reply){
    var request = new IsolateDataRequest._fromMap(req);
    var sendport = new RemoteSendPort.fromIsolateId(request.id);
    // TODO: what if sendport does not exist?

    sendport.send(req.data, req.reply)
  }
}

createRemoteIsolate(IsolateId id, String uri){
  DartCode.resolve(uri)
    .then((DartCode code) {
        new FileServer(code); // TODO: make fileserver
        var request = new SpawnIsolateRequest(id, code);
        new Network.isolateId(id).send(request.stream);
        });
}

// PUBLIC API //////////////////////////////////////////////////////////////////////
/**
  * Creates and spawns an isolate whose code is available at uri. 
  * The isolate is spawned on a remote node available in the distributed network.
  * Returns an IsolateSink feeding into the remote isolate stream
  */
IsolateSink streamSpawnUriRemote(String uri){
  var msgbox = new MessageBox();
  var id = new IsolateId();
  createRemoteIsolate(id, uri);
  
  msgbox.stream
    .transform(IsolateDataRequest.transform(id))
    .listen(new Network.isolateId(id).send);

  return msgbox.sink;
}

/**
  * Creates and spawns an isolate whose code is available at uri. 
  * The isolate is spawned on a remote node available in the distributed network.
  * Returns a sendport which is linked to the remote isolate ReceivePort
  */
RemoteSendPort spawnUriRemote(String uri){
  var sink = streamSpawnUriRemote(uri);
  var rp = new ReceivePort();
  rp.receive((data,_) => sink.add(data));
  return port.toSendPort();
}

/**
  * Host identification, 
  * must be initialized before node can partake in the network
  */
class Host {
  final String addr;
  final int port;
  static final Host _instance;
  factory Host() => _instance;
  Host.init(this.addr, this.port){
    Host._singelton = this;
  }
}

/// unique ID
class IsolateId implements Host{
  static int nextid = 0;
  final String addr = new Host().addr;
  final int port = new Host().port;
  final int id = nextid++;
  final int timestamp = new DateTime.now().millisecondsSinceEpoch;
  String toString() => "$addr:$port:$id:$timestamp";
  Map toJson() => { 'host' : host, 'id' : id,  'timestamp' : timestamp,  
    'addr': addr,  'port' : port}
}

class RemoteSendPort {
  final IsolateId id;
  SendPort isolate;

  static Map<String, RemoteSendPort> _portdb = {};
  static  RemoteSendPort.lookup(IsolateId id){
    if( _portdb.containsKey(id.toString()))
      return _portmap[id.toString()];
    return false;
  }

  RemoteSendPort(this.id, this.sendport){
    _portdb[id.toString()] = this;
  }
}


class RemoteReceivePort {
  IsolateId _id;
  RemoteSendPort _remotesendport;

  RemoteReceivePort(id,uri){
    _remotesendport = new RemoteSendPort(_id, spawnUri(uri));
  }

  RemoteSendPort toRemoteSendPort() => RemoteSendPort.lookup(_id);
}
