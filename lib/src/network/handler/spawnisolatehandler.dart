part of distributed_dart;

/**
 * Handler, responsible for setting up an isolate
 */
const String _NETWORK_SPAWN_ISOLATE_HANDLER = "spawn_isolate";
_spawnIsolateHandler(dynamic request, NodeAddress sender) {
  var req = new _spawnIsolateRequest.fromJsonMap(request);
  
  // callback, start isolate and send [_RemoteSendPort] to [senderAddress]
  spawn(String uri){
    var sendport = spawnUri(uri);
    var local = new _LocalIsolate(sendport);
    var remote = local.toRemoteSendPort();
    var response = new _spawnIsolateResponse(req.id, remote);
    response.sendTo(sender);
  }
  // setup local environment and spawn isolate
  req.code.createSpawnUriEnvironment(sender).then(spawn);
}

///[_spawnIsolateHandler] data type
class _spawnIsolateRequest {
  final _IsolateId id;
  final _DartProgram code;
  
  _spawnIsolateRequest(this.id,this.code);
  
  _spawnIsolateRequest.fromJsonMap(Map m):
    id = new _IsolateId.fromJsonMap(m['id']),
    code = new _DartProgram.fromMap(m['code']);  

  sendTo(NodeAddress node){
    new _Network(node).send(_NETWORK_SPAWN_ISOLATE_HANDLER, this);
  }
  Map<String,dynamic> toJson() => { 'id' : id, 'code' : code };
}

