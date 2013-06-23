part of distributed_dart;

const String _NETWORK_ISOLATE_DATA_HANDLER = "isolate_data"; 

_isolateDataHandler(dynamic request, NodeAddress senderAddress) {
  var id = request['id'];
  var msg = request['msg'];
  _RemoteSendPort reply = request['reply'];
  _LocalIsolate.Lookup(id).sendport.send(msg,reply.toSendPort());
}
