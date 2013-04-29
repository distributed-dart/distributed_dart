import 'dart:io';
import 'dart:async';

// example websocket server
// listens on ws://dart.dyndns.dk:15000
main(){
  listen(HttpServer server){
      print("listening for new connection");
      var sc = new StreamController();
      sc.stream
        .transform(new WebSocketTransformer())
        .listen((WebSocket ws) {
            int i = 0;
            ws.listen((data) {
              print("received: $data");
              ws.add("${i++}: $data");
              if( i > 10) ws.close();
              });
            });
      server.listen(sc.add);
  }
  HttpServer.bind("0.0.0.0",5000,0).then(listen);
}

