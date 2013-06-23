part of distributed_dart;

const String _NETWORK_ISOLATE_DATA_HANDLER = "isolate_data"; 

_isolateDataHandler(dynamic request, NodeAddress senderAddress) {
  var msg = new ObjectScanner().replaceRemoteSendPort(request['msg']);
  var id = new _IsolateId.fromJsonMap(request['id']);
  var reply = new _RemoteSendPort.fromJsonMap(request['reply']);
  _LocalIsolate.Lookup(id).sendport.send(msg,reply.toSendPort());
}
