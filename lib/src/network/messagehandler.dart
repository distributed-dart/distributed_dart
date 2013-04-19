part of distributed_dart;

abstract class MessageHandler {
  static String TYPE;
  abstract get String type
  void handleMessage(Map msg);
}

class MessageObserver {
  Map<String,List<MessageHandler>> _messageHandlers = {};

  append(MessageHandler handler) {
    if( ! _messageHandlers.containsKey(handler.Type))
      _messageHandlers[handler.Type] = [];

    _messageHandlers[handler.Type].add(handler);
  }

  // apply message on all handlers that subscribe to it
  listen(Map message){
    try {
      var type = Metadata.getType(message);
    } catch (e){
      _err(e);
      return;
    }

    if (! _messageHandlers.containsKey(type)){
      _err("no messagehandler registered for message of type $type");
      return;
    }
    
    for(MessageHandler h in _messageHandlers[type]){
      h.handleMessage(message);
    }
  }
}
