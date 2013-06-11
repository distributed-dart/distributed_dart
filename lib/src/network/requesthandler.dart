part of distributed_dart;

/**
  * Used by request handlers to distinguish request data type
  * If dart had Enum, this would be an Enum
  */
class RequestType {
  static const int Default = -1;
  static const int SpawnIsolate = 1;
  static const int IsolateData = 2;
}

/**
  * Used to assiciate a specific data request with an appropriate
  * request handler. 
  */
abstract class Request implements RequestHandler{
  final int type = RequestType.Default;

  Request();
  Request.empty();
  
  void requestHandler(Map request, Network reply);

  /// Test wheater to handle msg or not, based on [type]
  void runHandler(Map msg, Network reply) {
    try {
      if (msg['type'] == this.type) 
        requestHandler(msg, reply);
    } catch (e) {
      _err(e);
    }
  }
}

abstract class RequestHandler {
  final int type = RequestType.Default;
  void requestHandler(Map request, Network reply);
  void runHandler(Map msg, Network reply);
}

/**
  * Contains list of [RequestHandler]'s.
  */
class RequestHandlers {
  List<RequestHandler> _handlers = [];
  void add(RequestHandler r) => _handlers.add(r);
  Function runAll(Network reply){
    return (Map req) => _handlers.forEach((rh) => rh.runHandler(req, reply));
  }
}
