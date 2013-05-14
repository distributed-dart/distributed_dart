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
  * reequest handler. Must be extended to be used;
  */
abstract class Request {
  const int type = RequestType.Default;

  Request();
  Request._dummy();
  
  /// [RequestHandler] implementation
  void _requestHandler(Map request);

  /// Test wheater to handle msg or not, based on [type]
  void _runHandler(Map msg) {
    try {
      if (msg['type'] == this.type) 
        _requestHandler(msg);
    } catch (e) {
      _err(e);
    }
  }
}

/// requesthandlers have this format, 
typedef void RequestHandler(Map request);

/**
  * Contains list of [RequestHandler]'s.
  */
class RequestHandlers {
  List<RequestHandler> _handlers = new List<Request>();

  void add(Request request) => _handlers.add(request);
  void runAll(Map req) => _handlers.forEach((h) => h(req));
}
