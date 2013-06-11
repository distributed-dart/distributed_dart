part of distributed_dart;

// Request to spawn new isolate
class SpawnIsolateRequest extends Request {
  final int type = RequestType.SpawnIsolate;

  Map toJson(){
   var obj = { 'type' : type };
   return obj;
  }

  // 1.a) lookup code
  // 1.b) fetch code if missing
  // 2) spawn local isolate
  void requestHandler(Map request, Network reply){
    // TODO:
  }
}

// metadata for data sent to isolate
class IsolateDataRequest extends Request {
  final int type = RequestType.IsolateData;
  var id;
  var data;

  Map toJson(){
   var obj = { 'type' : type , 'data' : data };
   return obj;
  }

  IsolateDataRequest(this.id,this.data);

  // StreamTransformer to wrap input data in a IsolateDataRequest
  static StreamTransformer transform(id){
    return new StreamTransformer(
       handleData: (data, sink) => sink.add(new IsolateDataRequest(id, data))
       );
  }

  // request handler implementation for an IsolateDataRequest
  // 1. lookup remote sendport in sendport db
  // 2. send data to remote sendport
  void requestHandler(Map req, Network reply){
    // TODO:
  }
}




