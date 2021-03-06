part of distributed_dart;

/**
  * unique ID to distinguish isolates
  */
class _IsolateId {
  static int nextid = 0;

  final int id;
  final NodeAddress node;
  final int ts;
  
  _IsolateId():
   id = nextid++,
   node = NodeAddress._localhost,
   ts = new DateTime.now().millisecondsSinceEpoch;
   
  
  _IsolateId.fromJsonMap(Map map):
    id = map['id'],
    node = new NodeAddress.fromJsonMap(map['node']),
    ts = map['ts'];
    

  String toString() => "$node:$id:$ts";
  
  Map toJson(){
   var obj = {
     'id' : id,
     'node' : node,
     'ts' : ts
   }; 
   return obj;
  }
  
  /// identical and '==' overload
  int get hashCode => node.hashCode + id + ts;
  bool operator ==(other) {
    if (identical(this, other)) {
      return true;
    } 
    return (other is _IsolateId && 
            id == other.id && 
            node == other.node &&
            ts == other.ts);
  }
}

/**
  * Sendport Proxy
  * Reference to a specific [_LocalIsolate].
  * To send a [SendPort] to a remote host, it must be wrapped in a
  * [_LocalIsolate] and sent as a [_RemoteSendPort]
  */
const String _REMOTE_SENDPORT_MAGIC_COOKIE = """
+8aUvJ957Zor2AaFfhAkEQlD468yNq4MNqgp5SmpkUtNJevIOIFEDdgrqOUtQNhQMH4jO8I2f7Pq
z+nutYI2iC3gMx8CxUQGrinBC+UDwYso6p/bhasaJecbBp2TMrxu48K3CTRJuDXqAGi/BgAZ7+y8
Dsw/I58To2onq3MYuV8Hf810Le4z8WZhl+6/duvBsU4Q0CMNFGENaQKISrJ/HTceDYDF7lN+iXMk
Qs9qfTSr0AgIP5vn4og6wT4eubaKggx1fiPXLgFFyUqrEde2m7zxWDeVLM0hAkwcXeIiLnCPT/ZU
nKdd6Dw/UZlCpQrOzyTh4SDgQEuwxvvrMaLDF30aPhtw+AqKcnzJvy5GjjdKCgo2lWr1+c/1sB2Z
dkBfw9luYygXgkovqjnR14Vw63vLcV6X3B90zYB+QbU1UFuguKBuYwhrrpaWgtffIEnbXum6rUIa
t842KsY9bZ0vBHWXqwYA1lu2Jomq9Etv+X0nT+ICEc4Yzufa25VsT4XLYA65E44GhGj6DBdHCNu5
MOdAQ1TLZc9qL4wA/OL5w0EObAXw9f8l1onoHIsEHrdZPHjWh4S2evuUmcYoPGZCC6vL3WFADI1F
6E5l8InGJd05lEPkhVBfh/bR+FnvZl+RC39dkUsQboEjn30cDpQbmp0oRJKau9JlMOfQSUYTVv8=
""";
class _RemoteSendPort {
  final _IsolateId id;
  final NodeAddress node;
  final String RSPID = _REMOTE_SENDPORT_MAGIC_COOKIE;

  _RemoteSendPort(this.id): 
    node = NodeAddress._localhost;

  _RemoteSendPort.fromJsonMap(Map m):
    id = new _IsolateId.fromJsonMap(m['id']),
    node = new NodeAddress.fromJsonMap(m['node']);
  
  // map a SendPort;
  SendPort toSendPort(){
    var rp = new ReceivePort();
    rp.receive((msg,reply){
      var rsp = new _LocalIsolate(reply).toRemoteSendPort();
      send(msg, rsp);
    });
    return rp.toSendPort();
  }

  void send(dynamic msg, _RemoteSendPort reply){
    var rspmsg = new _ObjectScanner().replaceSendPort(msg);
    var request = { 'msg' : rspmsg,'reply' : reply, 'id' : id };
    new _Network(node).send(_NETWORK_ISOLATE_DATA_HANDLER, request); 
  }
  
  Future call(dynamic data){
    var rp = new ReceivePort();
    var sp = rp.toSendPort();
    var local = new _LocalIsolate(sp);
    send(data,local.toRemoteSendPort());
    
    var c = new Completer();
    rp.receive((msg,_) => c.complete(msg));
    return c.future;
  }
  
  Map toJson() =>  {'id' : id,'node' : node , 'RSPID' : RSPID };
}

/**
  * Lookup table, contains reference to all physical isolates spawned on the
  * current Node.
  * 
  * The table contains a mapping between an [_IsolateId] and a [SendPort]
  * [SendPort]'s can be created manually, and bound to a [_LocalIsolate]
  * object, or it can be created directly in via a [_LocalIsolate] constructor.
  */
class _LocalIsolate{
  final _IsolateId id = new _IsolateId();
  final SendPort sendport;
  
  /// [_LocalIsolate] lookup table, key is (string) IsolateId
  static Map<_IsolateId, _LocalIsolate> _isolatemap = new Map();
  static Map<SendPort, _LocalIsolate> _sendportmap = new Map();
  
  _RemoteSendPort toRemoteSendPort() => new _RemoteSendPort(id);

  /** 
    * Search for [_LocalIsolate] instance
    * returns null if isolate does not exist.
    */
  static _LocalIsolate Lookup(_IsolateId id){
    var key = id;
    if( _isolatemap.containsKey(key))
      return _isolatemap[key];
  }
  
  _LocalIsolate._create(this.sendport){
    _isolatemap[id] = this;
    _sendportmap[sendport] = this;
  }
  
  /// bind a new sendport to the [_LocalIsolate] lookup table
  factory _LocalIsolate(SendPort port){
    if(_sendportmap.containsKey(port)){
      return _sendportmap[port];
    }
    return new _LocalIsolate._create(port);
  }
}

class _RemoteProxy {
  /// requestid mapped to functions that completes a future
  static Map subscribers = new Map();
  
  /// returns a future, which is completed when the node is notified by
  /// a requesthandler
  static Future<_RemoteSendPort> subscribe(_IsolateId requestid){
    var c = new Completer();
    subscribers[requestid] = (_RemoteSendPort rsp){
      c.complete(rsp);
      subscribers.remove(requestid);
    };
    return c.future;
  }
  
  static notify(_IsolateId, _RemoteSendPort){
    subscribers[_IsolateId](_RemoteSendPort);
  }
}

// PUBLIC function
SendPort spawnUriRemote(String uri, NodeAddress node){
  var requestId = new _IsolateId();
  var rp = new ReceivePort();
  var buffer = new StreamController();
  rp.receive((msg,reply) => buffer.sink.add({'msg':msg,'reply':reply}));
  
  _RemoteProxy
    .subscribe(requestId)
    .then((_RemoteSendPort rsp){
      buffer.stream.listen((data){
        var msg = data['msg'];
        var sp = data['reply'];
        var local = new _LocalIsolate(sp);
        rsp.send(msg, local.toRemoteSendPort());
      });
    });
  
  
  _DartCodeDb.resolveDartProgram(uri).then((_DartProgram dp){
    new _spawnIsolateRequest(requestId,dp).sendTo(node);
  });

  return rp.toSendPort();
}