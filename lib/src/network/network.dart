part of distributed_dart;

// Mock Classes, will be added later ------------------------------------------
// ----------------------------------------------------------------------------
class DartCode {
  String name = "libname";
  String hash = "7576f7rd";
  String basedir = "/path/to/library";
  Map<String,String> files = { 
    '657de657f' : 'src/somefile.dart', 
    '6579e43f' : 'src/module/anotherfile.dart'
  };
  DartCode(this.name, this.hash, this.basedir, this.files);
  DartCode._dummy();
}

class SourceLibrary{
  static Future<DartCode> lookup({String uri, String hash}){
    return new Future.value(new DartCode._dummy());
  }
}


// Stream Transformers --------------------------------------------------------
// ----------------------------------------------------------------------------

// Prefixes a the bytelist object with the size of the json string
// size prefixe is a 64 bit integer, encoded as Uint8List(8)
class ByteListEncoder extends StreamEventTransformer {
    void handleData (Uint8List data, EventSink sink) {
      var size = new Uint8List(8);
      new ByteData.view(size.buffer).setUint64(0,data.length);
      _log("add header: ${data.length} -> $size");
      sink.add(size);
      sink.add(data);
    }
}

// split concatinated objects, or assemble larger objects which has been split 
class ByteListDecoder extends StreamEventTransformer {
  int remaining = -1;
  List<int> obj = [];

  void handleData(Uint8List data,EventSink<List<int>> sink){
    var idx = 0;
    var dataView = new ByteData.view(data.buffer);
    _log("received ${data.length} bytes");
    
    while (idx < data.length) {
      // prepare to read a new object
      if(remaining == -1 ){
        remaining = dataView.getUint64(idx);
        idx+=8;
        obj = new List();
        _log(" > header: ${data.sublist(0,8)} -> size: $remaining bytes");
      }

      // try to get the entire object first
      // if the data is incomplete, add data to buffer, and ajust remaining
      List objpart = [];
      try {
        objpart = data.sublist(idx,idx+remaining);
      } 
      catch (e) {
        objpart = data.sublist(idx); // sublist from index to end
      } 
      finally {
        remaining -= objpart.length;
        idx += objpart.length;
        obj.addAll(objpart);
        _log(" > read ${objpart.length} bytes");
      }

      // object is assembled, write to sink, and mark that we are ready to
      // read the next object.
      if( remaining == 0) {
        sink.add(obj);
        remaining = -1;
        _log(" > done: total ${obj.length} bytes");
      }
    }
  }
}

class JsonEncoder extends StreamEventTransformer <dynamic,String> {
  void handleData(dynamic data, EventSink<String> sink){
    sink.add(json.stringify(data));
  }
}

class JsonDecoder extends StreamEventTransformer<String, dynamic> {
  void handleData(String data, EventSink<dynamic> sink){
    sink.add(json.parse(data));
  }
}

class MetadataEncoder extends StreamEventTransformer<dynamic,Map> {
  Map _metadata;
  MetadataEncoder(this._metadata) : super();

  void handleData(dynamic data, EventSink<Map> sink){
    var obj = _metadata;
    obj['data'] = data;
    sink.add(obj);
  }
}


// Network --------------------------------------------------------------------
// ----------------------------------------------------------------------------
typedef void MsgHandler(Map msg);
class MessageHandler {
  Map<String,List<MsgHandler>> _msgHandlers = {};

  add(String msgtype, MsgHandler handler) {
    if(! _msgHandlers.containsKey(msgtype)){
      _msgHandlers[msgtype] = [];
    }
    _msgHandlers[msgtype].add(handler);
  }

  // apply message on all handlers that subscribe to it
  handleMessage(Map message){
    _msgHandlers.forEach((key, hlist) {
        if(message.containsKey(key)){
          hlist.forEach((handler) => handler(message));
        }
      });
  }
}

class FileServer {
  static String TYPE = 'getfile';
  static MsgHandler handler(DartCode lib) {
    return (request)  => null; // TODO:  reply with file if request is valid file
  }
}

class Server {
  MessageHandler _msghandler = new MessageHandler();
  static Map ADDR = {'host': '127.0.0.1', 'port':'12345' }; // TODO: fixme

  Server(){
    ServerSocket.bind('0.0.0.0',12345).then(
        (serversocket) => serversocket.listen(
          _onConnection,
          onError: (e) => _err("ServerSocket Error: $e")));
  }

  addHandler(String type, MsgHandler handler) => _msghandler.add(type, handler);

  _onConnection(Socket client){
    client
      .transform(new ByteListDecoder())
      .transform(new StringDecoder())
      .transform(new JsonDecoder())
      .listen(_msghandler.handleMessage);
  }

}

class Network {
  Socket _socket;
  Completer _socketReady = new Completer();
  static Server server = new Server();
  static Map<String, Network> _instances = {};

  factory Network(String id){
    var addr = IsolateLookup.whereIs(id);
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
      .listen((d) => _socket.add(d))
      .pause(_socketReady.future);
  }
}


// Isolates -------------------------------------------------------------------
// ----------------------------------------------------------------------------

class IsolateLookup {
  static Map whereIs(String isolateId){
    return { 'host': '127.0.0.1', 'port' : 12345 };
  }
}

// represents a local isolate owned by a remote host
class LocalIsolate {
  String _id;
  SendPort _port;

  static Map<String,LocalIsolate> _instances = {};
  factory LocalIsolate(id,uri){
    if(! _instances.containsKey(id)){
       _instances[id] = new LocalIsolate._(id,uri);
    }
    return _instances[id];
  }

  add(dynamic data) => _port.send(data);
  LocalIsolate._(this._id,String uri) : _port = spawnUri(uri);
}


// generate unique id for new isolate
class IsolateId {
  static int _id = 0;
  static String hostname = 'myhost';
  static String get next => "$hostname:${_id++}";
}

// represents an isolate on a remote host
class _RemoteIsolate {

  static IsolateSink spawn(String uri){
    var box = new MessageBox();
    
    // setup remote isolate
    var id = createRemoteIsolate(uri);

    // send incomming data to remote isolate
    sendData(id, box.stream);

    return box.sink;
  }

  static String createRemoteIsolate(String uri){
    // generate id for new isolate
    String isolateId = IsolateId.next;

    // find all code associated with uri, and setup a local fileserver
    SourceLibrary.lookup(uri: uri).then((code){
        Network.server.addHandler(FileServer.TYPE, FileServer.handler(code));
        var request = { 
          'spawn' : code.hash, 
          'id' : isolateId,
          "${FileServer.TYPE}" : Server.ADDR };
          // TODO, get available host, and send reequest to spawn isolate
        });
    return isolateId;;
  }
 
  static void sendData(id, Stream stream){
    var network = new Network(id);
    stream
      .transform(new MetadataEncoder({'isolateid' : id}))
      .listen(network.send);
  }
}

IsolateSink SpawnUriRemote(String uri) => _RemoteIsolate.spawn(uri);
