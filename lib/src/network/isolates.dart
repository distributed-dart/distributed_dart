part of distributed_dart;

class IsolateId {
  final String id;

  // generate unique id 
  static String hostname = 'myhost';
  static int _id = 0;
  static String _nextId(){
    int timestamp = new DateTime.now().millisecondsSinceEpoch;
    return "${hostname}:${timestamp}:${_id++}";
  }

  IsolateId(): id = _nextId();
  IsolateId._fromId(this.id);

  toString() => id;
  toJson() => toString();
}

// Request to spawn new isolate
class SpawnIsolateRequest implements Request {
  const int type = RequestType.SpawnIsolate;
  final IsolateId id;
  final DartCode code;

  SpawnIsolateRequest(this.id, this.code);

  SpawnIsolateRequest.fromMap(Map data):
    this.id = data['id'],
    this.code = new DartCode.fromMap(data['code']);
  

  toJson() => { 'type' : type,'code' : code, 'id' : id };

  static void requestHandler(Map request){
    var r = new SpawnIsolateRequest.fromMap(request);
    // TODO: 
    // 1.a) lookup code
    // 1.b) fetch code if missing
    // 2) spawn local isolate
  }

  Stream get stream => new Stream.fromIterable(toJson());
}

// metadata for data sent to isolate
class IsolateDataRequest implements Request {
  const int type = RequestType.IsolateData;
  final IsolateId id;
  final dynamic data;

  IsolateDataRequest(this.id, this.data);
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

  static void requestHandler(Map request){
    var r = new IsolateDataRequest._fromMap(request);
    // TODO:
    // 1. Lookup local isolate id
    // 2. buffer data if isolate is not created yet
    // 3. send data to isolate
  }
}

createRemoteIsolate(IsolateId id, String uri){
  var code = new DartCode(); // TODO: integrate with library lookup: code = lookup(uri);
  var fs = new FileServer(code);  // TODO: make file server
  var request = new SpawnIsolateRequest(id, code);
  new Network.isolateId(id).send(request.stream);
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
SendPort spawnUriRemote(String uri){
  var sink = streamSpawnUriRemote(uri);
  var rp = new ReceivePort();
  rp.receive((data,_) => sink.add(data));
  return port.toSendPort();
}
