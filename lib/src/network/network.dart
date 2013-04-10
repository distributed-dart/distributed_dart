import 'dart:io';
import 'dart:async';
import 'dart:isolate';
import 'dart:json' as json;


/**
  * encode string with header
  * format: "inputstring" -> "11,inputstring"
  */
String encode(var input){
  var js = json.stringify(input);
  return "${js.length},$js";
}

/**
  * split string to a list of strings, according to string headers
  */
List decode(String input){
  // match group 1 is string length, match group 2 is the rest of the string
  var regex = new RegExp(r'^([0-9]+),(.*)',multiLine:true);
  var output = new List();
  while (regex.hasMatch(input)) {
    var match = regex.firstMatch(input);
    int  size = int.parse(match.group(1),radix:10);
    String tail = match.group(2);
    String data = tail.slice(0,size);
    input = tail.slice(size);
    try {
      output.add(json.parse(data));
    } on FormatException catch(e) {
      stderr.add("decode: $e");
    }
  }
  return output;
}

_onError(e) =>  print("Error: $e");
_onDone() =>  print("Done");

_onConnection(Socket conn){
  _onData(data){
    data = new String.fromCharCodes(data);
    for(String s in decode(data)){
      print("${s.runtimeType} : $s");
    }
  }
  conn.listen(_onData, onError: _onError, onDone: _onDone);
}

/**
  * Start server
  */
startServer(){
  ServerSocket.bind('0.0.0.0',12345).then((serversocket){
      serversocket.listen(
        _onConnection,
        onError: _onError, 
        onDone: _onDone);
      });
}

/**
  * Setup socket connection to serve, and pipe input on stream
  * to socket
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
  box.stream.map(encode)
    .listen((d) => socket.write(d))
    .pause(untilSignal.future);

  Socket.connect('127.0.0.1',12345)
    .then((s){
        // assign socket, and unpause stream
        socket = s;
        untilSignal.complete();
    });
  return box.sink;
}

// test
main(){
  startServer();
  var remote = spawnRemote("not_implemented");
  for(int i = 0; i < 10; i++){
    remote.add({'msg': 'hello', 'id': i});
  }
}
