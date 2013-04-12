part of distributed_dart;
_decoder(){
  int remaining = -1;
  List<int> obj = [];

  _decode(Uint8List data,EventSink<List<int>> sink){
    var idx = 0;
    var dataView = new ByteData.view(data.buffer);
    _log("received ${data.length} bytes");
    
    while (idx < data.length) {
      // prepare to read a new object
      if(remaining == -1 ){
        remaining = dataView.getUint64(idx);
        idx+=8;
        obj = new List();
        _log(" > header: ${data.sublist(0,8)} -> size: $remaining bytes");
      }

      // try to get the entire object first
      // if the data is incomplete, add data to buffer, and ajust remaining
      List objpart = [];
      try {
        objpart = data.sublist(idx,idx+remaining);
      } 
      catch (e) {
        objpart = data.sublist(idx); // sublist from index to end
      } 
      finally {
        remaining -= objpart.length;
        idx += objpart.length;
        obj.addAll(objpart);
        _log(" > read ${objpart.length} bytes");
      }

      // object is assembled, write to sink, and mark that we are ready to
      // read the next object.
      if( remaining == 0) {
        sink.add(obj);
        remaining = -1;
        _log(" > done: total ${obj.length} bytes");
      }
    }
  }
  return new StreamTransformer(handleData: _decode);
}

/**
  * Start server
  * 
  * TODO: add a handler to 
  */
startServer(){
  _onConnection(Socket client){
    // Placeholder handler
    messageHandler(var msg){
      _log("Received object of type ${msg.runtimeType}");
      if (msg is List)  _log(" > size: ${msg.length}");
      if (msg is String){
        msg = (msg.length > 70) ? "${msg.slice(0,70)}..." : msg;
        _log(" > ${msg}");
      }
    }

    var _from_json = new StreamTransformer(
        handleData: (d,s) => s.add(parse(d)));

    client
      .transform(_decoder())
      .transform(new StringDecoder())
      .transform(_from_json)
      .listen(messageHandler);
  }

  ServerSocket.bind('0.0.0.0',12345).then(
      (serversocket) => serversocket.listen(
          _onConnection,
          onError: (e) => _err("ServerSocket Error: $e")));
}

/**
  * Setup socket connection to serve, and pipe input on stream
  * to socket
  * 
  * TODO: refactor into proxy module
  */
IsolateSink spawnRemote(String lib){

  // by subscribing to the stream, and pausing it, data written to the 
  // sink before the socket is connected is buffered, 
  // Hack, because we dont have a socket object until the connect()
  // future completes. we use a null socket, in the stream listener, 
  // which is assigned to a concrete socket when the connection is 
  // established. This is possible because the stream is paused.
  var box = new MessageBox();
  Socket socket = null;
  var untilSignal = new Completer();

  var  _to_json = new StreamTransformer(
      handleData: (d,s) => s.add(stringify(d)));

  var _addHeader = new StreamTransformer(
      handleData: (d,s) {
        var size = new Uint8List(8);
        new ByteData.view(size.buffer).setUint64(0,d.length);
        _log("add header: ${d.length} -> $size");
        s.add(size);
        s.add(d);
        });

  box.stream
    .transform(_to_json)
    .transform(new StringEncoder())
    .transform(_addHeader)
    .listen((d) => socket.writeBytes(d))
    .pause(untilSignal.future);

  Socket.connect('127.0.0.1',12345)
    .then((s){
        // assign socket, and unpause stream
        socket = s;
        untilSignal.complete();
    });
  return box.sink;
}

