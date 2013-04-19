part of distributed_dart;

// represents a local isolate owned by a remote host
class LocalIsolate {
  String _id;
  SendPort _port;

  static Map<String,LocalIsolate> _instances = {};

  factory LocalIsolate(id){
    if(! _instances.containsKey(id)){
      // oh no, isolate is not spawned
      // TODO: either make a buffer, or throw an exception
    }
    return _instances[id];
  }

  factory LocalIsolate.spawn(id, uri){
       _instances[id] = new LocalIsolate._(uri);
  }

  add(dynamic data) => _port.send(data);

  LocalIsolate._(String uri) : _port = spawnUri(uri);
}

// generate unique id for new isolate
class IsolateId {
  static int _id = 0;
  static String hostname = 'myhost';
  static String get next => "$hostname:${_id++}";
}

class SpawnIsolateRequest {
  final String codehash;
  final Map fileserver;
  final string isolateid;

  SpawnIsolateRequest(this.hash, this.server, this.isolateid);

  toJson() {
    return {
      'codehash' : codehash, 
      'fileserver' : fileserver, 
      'isolateid': isolateid };
}

SpawnIsolateHandler extends MessageHandler {
  static String TYPE = 'SPAWNISOLATE';
  get String Type = SpawnIsolateHandler.TYPE;

  void handler(Map msg) {
    // lookup local code uri, or request it from fileserver
    SourceLibrary.getUri(msg['codehash'],msg['fileserver'])
      .then((uri) => new LocalIsolate.spawn((msg['isolateid'], uri));
  }
}

IsolateDataHandler extends MessageHandler {
  static String TYPE = 'ISOLATEDATA';
  get String Type = IsolateDataHandler.TYPE;

  // TODO: add buffer in case data has been sent to an isolate before it was opened
  void handler(Map msg){
    LocalIsolate(msg['id']).add(Metadata.getData(msg));
  }
}

IsolateSink streamSpawnUriRemote(String uri) {
  sendSpawnRequest(code, host){
    var code = list[0];
    var host = list[1];
    network.connect(host)

    network = new Network(isolateid, host);
    var spawn_meta = new Metadata(SpawnIsolateHandler.TYPE, {});
    new Future(new SpawnIsolateRequest(code['hash'], id))
      .asStream()
      .transform(spawn_meta)
      .listen(network.send);
  }

  // generate id for new isolate
  var msgbox = new MessageBox();
  String id = IsolateId.next;

  var isolate_meta  = new Metadata(IsolateDataHandler.TYPE, {'id' : id });
  msgbox.stream
    .transform(new MetadataEncoder(metadata))
    .listen(network.send);

  // request code and remote hostaddr
  Future code = SourceLibrary.uri(uri);
  Future remotehost = MasterServer.getHost();
  Future.wait( [ code, remotehost ])
    .then((v) => sendSpawnRequest(v[0], v[1]));

  return msgbox.sink;
}
