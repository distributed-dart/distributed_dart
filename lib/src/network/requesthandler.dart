part of distributed_dart;

typedef RequestHandler(dynamic request, NodeAddress senderAddress);

/**
  * Contains list of [RequestHandler]'s.
  */
class _RequestHandler {
  static const String REQUEST_TYPE = "type";
  static const String NODE_ADDRESS = "address";
  static const String DATA         = "data";
  static Set<String> allowed = new Set();
  
  static allow(String handler) => allowed.add(handler);
  static disallow(String handler) => allowed.remove(handler);
  
  static void notify(Map jsonMap) {
    String requestType  = jsonMap[REQUEST_TYPE];
    NodeAddress sender  = new NodeAddress.fromJsonMap(jsonMap[NODE_ADDRESS]);
    var data            = jsonMap[DATA];
    
    _log("incomming request from ${sender.host} : $requestType");
    
    if (! allowed.contains(requestType)){
      _log(" > request denied");
      return;
    }

    switch (requestType){
      case _NETWORK_FILE_HANDLER:
        _fileHandler(data, sender);
        break;
        
      case _NETWORK_FILE_REQUEST_HANDLER:
        _fileRequestHandler(data, sender);
        break;
        
      case _NETWORK_ISOLATE_DATA_HANDLER:
        _isolateDataHandler(data, sender);
        break;
        
      case _NETWORK_SPAWN_ISOLATE_HANDLER:
        _spawnIsolateHandler(data, sender);
        break;
        
      case _NETWORK_SPAWN_RESPONSE_HANDLER:
        _spawnIsolateResponseHandler(data, sender);
        break;
    }
  }
  
  /**
   * Wrap data in map with type and sender annotation
   */
  static Map annotateData(String type, dynamic data) {
    var map = new Map();
    
    map[REQUEST_TYPE] = type;
    map[NODE_ADDRESS] = NodeAddress._localhost;
    map[DATA]         = data;
    
    return map;
  }
}
