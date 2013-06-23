part of distributed_dart;

/**
 * Handler, responsible for setting up an isolate
 */
const String _NETWORK_SPAWN_ISOLATE_HANDLER = "spawn_isolate";
_spawnIsolateHandler(dynamic request, NodeAddress senderAddress) {
  var reply = new Network(senderAddress);
  
  // callback, start isolate and send [_RemoteSendPort] to [senderAddress]
  spawn(String uri){
    var sendport = spawnUri(uri);
    var local = new _LocalIsolate.fromSendPort(sendport);
    var remote = local.toRemoteSendPort();
    var response = {};
    reply.send(_NETWORK_SPAWN_RESPONSE_HANDLER, response);
  }
  
  // setup local environment and spawn isolate
  var sr = new _spawnRequest(request);
  sr.dartProgram.createSpawnUriEnvironment(reply).then(spawn);
}



/**
 * Handler, receives a [_RemoteSendPort] as response to a spawnRemoteUri call
 */
const String _NETWORK_SPAWN_RESPONSE_HANDLER = "spawn_isolate";
_spawnIsolateResponseHandler(dynamic request, NodeAddress senderAddress){
}

class _spawnRequest {
  _IsolateId requestId;
  _DartProgram dartProgram;
  _spawnRequest(data);
}

class _spawnResponse {
  _IsolateId requestId;
  _RemoteSendPort remotePort;
}
