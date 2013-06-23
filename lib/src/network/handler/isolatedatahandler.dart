part of distributed_dart;

const String _NETWORK_ISOLATE_DATA_HANDLER = "isolate_data"; 

_isolateDataHandler(dynamic request, NodeAddress senderAddress) {
  // scan for _RemoteSendPort objects in the message, and replace with SendPort
  var msg = new ObjectScanner().replaceRemoteSendPort(request['msg']);
  var id = new _IsolateId.fromJsonMap(request['id']);
  var reply = new _RemoteSendPort.fromJsonMap(request['reply']);
  // send message to the found isolate
  _LocalIsolate.Lookup(id).sendport.send(msg,reply.toSendPort());
}
