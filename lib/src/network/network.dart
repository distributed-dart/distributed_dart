import 'dart:io';
import 'dart:async';
import 'dart:isolate';


/**
  * encode string with header
  * format: "inputstring" -> "11,inputstring"
  */
String encode(String input) => "${input.length},$input";

/**
  * split string to a list of strings, according to string headers
  */
List<String> decode(String input){
  var regex = new RegExp(r'([0-9]+),(.*)',multiLine:true);
  var output = new List();
  while (regex.hasMatch(input)) {
    var match = regex.firstMatch(input);
    int  size = int.parse(match.group(1),radix:10);
    String tail = match.group(2);
    String data = tail.slice(0,size);
    input = tail.slice(size);
    output.add(data);
  }
  return output;
}

_onError(e) =>  print("Error: $e");
_onDone() =>  print("Done");

_onConnection(Socket conn){
  _onData(data){
    data = new String.fromCharCodes(data);
    for(String s in decode(data)){
      print(s);
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
  var buffer = new List();
  var bufferstream = new Stream.fromIterable(buffer).map(encode);
  var box = new MessageBox();
  Socket socket = null;
  var untilSignal = new Completer();
  box.stream.map(encode)
    .listen((d) => socket.write(d))
    .pause(untilSignal.future);

  Socket.connect('127.0.0.1',12345)
    .then((s){
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
    remote.add("abc${i}def");
  }
}
