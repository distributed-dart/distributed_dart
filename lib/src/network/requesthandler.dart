part of distributed_dart;

typedef RequestHandler(dynamic request, String networkReplyId);

/**
  * Contains list of [RequestHandler]'s.
  */
class RequestHandlers {
  static const String REQUEST_TYPE      = "type";
  static const String NETWORK_SENDER_ID = "id";
  static const String DATA              = "data";
  
  Map<String,RequestHandler> _handlers = new Map();
  
  void add(String type, RequestHandler r) {
    if (!_handlers.containsKey(type)) {
      _handlers[type] = r;
    } else {
      var m = "Already assigned RequestHandler to request type: $type.";
      new UnsupportedOperationError(m);
    }
  }
  
  void remove(String type) {
    if (_handlers.containsKey(type)) {
      _handlers.remove(type);      
    } else {
      var m = "Cannot remove non existing RequestHandler for type: $type.";
      new UnsupportedOperationError(m);
    }
  }
  
  void notify(Map jsonMap) {
    String requestType     = jsonMap[REQUEST_TYPE];
    String networkSenderId = jsonMap[NETWORK_SENDER_ID];
    var data               = jsonMap[DATA];
    
    _handlers[requestType](data, networkSenderId);
  }
  
  static Map toMap(String type, dynamic data) {
    var map = new Map();
    
    map[REQUEST_TYPE]      = type;
    map[NETWORK_SENDER_ID] = NodeAddress._localhost;
    map[DATA]              = data;
    
    return map;
  }
}
