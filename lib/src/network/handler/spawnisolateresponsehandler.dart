part of distributed_dart;

/**
 * Handler, receives a [_RemoteSendPort] as response to a spawnRemoteUri call
 */
const String _NETWORK_SPAWN_RESPONSE_HANDLER = "spawn_isolate_respose";
_spawnIsolateResponseHandler(dynamic request, NodeAddress sender){
  var req = new _spawnIsolateResponse.fromJsonMap(request);
  _RemoteProxy.notify(req.id, req.rsp);
}


///[_spawnIsolateResponseHandler] data type
class _spawnIsolateResponse {
  final _IsolateId id;
  final _RemoteSendPort rsp;

  _spawnIsolateResponse(this.id,this.rsp);
  
  _spawnIsolateResponse.fromJsonMap(Map m):
    id = new _IsolateId.fromJsonMap(m['id']),
    rsp = new _RemoteSendPort.fromJsonMap(m['rsp']);
  
  sendTo(NodeAddress node){
    new _Network(node).send(_NETWORK_SPAWN_RESPONSE_HANDLER, this);
  }
  
  Map<String,dynamic> toJson() => { 'id' : id, 'rsp' : rsp };
}
