part of distributed_dart;

// Prefixes a the bytelist object with the size of the json string
// size prefixe is a 64 bit integer, encoded as Uint8List(8)
class ByteListEncoder extends StreamEventTransformer {
    void handleData (List data, EventSink sink) {
      var size = new Uint8List(8);
      new ByteData.view(size.buffer).setUint64(0,data.length);
      _log("add header: ${data.length} -> $size");
      sink.add(size);
      sink.add(data);
    }
}

// split concatinated objects, or assemble larger objects which has been split 
class ByteListDecoder extends StreamEventTransformer {
  int remaining = -1;
  List<int> obj = [];

  void handleData(Uint8List data,EventSink<List<int>> sink){
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
}

class JsonEncoder extends StreamEventTransformer <dynamic,String> {
  void handleData(dynamic data, EventSink<String> sink){
    try {
      sink.add(json.stringify(data));
    } catch (e){
      _err(e);
    }
  }
}

class JsonDecoder extends StreamEventTransformer<String, dynamic> {
  void handleData(String data, EventSink<dynamic> sink){
    sink.add(json.parse(data));
  }
}

class JsonCyclicError implements Exception {
  final String message;
  const JsonCyclicError([this.message = ""]);
  String toString() => "Cyclic error!: $message";
}

class NotSerializableObjectException implements Exception {
  final String message;
  const NotSerializableObjectException([this.message = ""]);
  String toString() => "NotSerializableObjectException: $message";
}

// Gift from Jacob. Should definitely just made ​​a little about fit into the rest
/**
 * Scans objects, for SendPort and _RemoteSendPorts, and rewrites them
 * Used to support embedding SendPorts inside the payload of a message.
 */
class ObjectScanner {
  final int _SENDPORT = 1;
  final int _REMOTESENDPORT = 2;
  
  List<Object> seen = new List<Object>();
  
  void checkCycle(final object) {
    seen.forEach((Object o) {
      if (identical(o, object)) {
        throw new JsonCyclicError(object.toString());
      }     
    });
    seen.add(object);
  }

  /// replace SendPort with _RemoteSendPort,
  Object replaceSendPort(final object) {
     return _scanAndReplaceObject(object, _SENDPORT);
  }
  
  /// replace _RemoteSendPort with SendPort,
  Object replaceRemoteSendPort(final object) { 
    return _scanAndReplaceObject(object, _REMOTESENDPORT);
  }
  
  // replace SendPort with _RemoteSendPort, or vice versa
  Object _scanAndReplaceObject(final object, int replace) {
    if (object is num) {
      return object;
    } else if (object is bool) {
      return object;
    } else if (object == null) {
      return object;
    } else if (object is String) {
      return object;
    } else if (object is List) {
      checkCycle(object);
      List a = object;
      if (a.length > 0) {
        a = a.map((Object o) {
          return _scanAndReplaceObject(o, replace);
        }).toList(growable:false);
      }
      seen.remove(object);
      return object;
    } else if (object is Map) {
      
      // HACK, we cannot detect type "_RemoteSendPort", because it is a
      // JSON map at this time. So instead we have added a magic cookie.
      // This should really be expressed by the message header, instead
      // of inside the payload of the object, since this could be exploited.
      if(replace == _REMOTESENDPORT && 
          object.containsKey("RSPID") &&
          object["RSPID"] == _REMOTE_SENDPORT_MAGIC_COOKIE) {
        return new _RemoteSendPort.fromJsonMap(object).toSendPort();
      }
      
      checkCycle(object);
      Map<String, Object> m = object;
      
      m.keys.forEach((String key) {
        if (key is String) {
          m[key] = _scanAndReplaceObject(m[key], replace);
        } else {
          throw new NotSerializableObjectException("Key must be string.");
        }
      });
      seen.remove(object);
      return object;
    } else if (object is SendPort && replace == _SENDPORT) {
      return new _LocalIsolate(object).toRemoteSendPort(); 
    } else if (object is _RemoteSendPort && replace == _REMOTESENDPORT) {
      _err("Found _RemoteSendPort, this should not happen");
      return object.toSendPort();
    } else {
      checkCycle(object);
      var r = _scanAndReplaceObject(object.toJson(), replace);
      seen.remove(object);
      return r;
    }
  }
}
