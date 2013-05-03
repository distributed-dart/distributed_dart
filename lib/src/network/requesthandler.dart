part of distributed_dart;

/**
  * Used by request handlers to distinguish request data type
  * If dart had Enum, this would be an Enum
  */
class RequestType {
  static const int SpawnIsolate = 1;
  static const int IsolateData = 2;
}

typedef void RequestHandler(Map request);
abstract class Request {
  const int type = -1;
}

/**
  * Contains RequestType -> List<RequestHandler> Mapping
  */
class RequestHandlerList {

  Map<int, List<RequestHandler>> handlers = new Map<int, List<RequestHandler>>();
  void add(int type, RequestHandler handler) {

    if( ! handlers.containsKey(type)){
      handlers[type] = [];
    }
    handlers[type].add(handler);
  }

  runAll(Map req){
    try {
      var type = req['type'];
      handlers[type].forEach((h) => h(req));
    } catch (e) {
      _err(e);
    }
  }
}


