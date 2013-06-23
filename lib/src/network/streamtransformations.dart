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
      print(data.runtimeType);
      print(data);
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
class ObjectScanner {
  List<Object> seen = new List<Object>();
  
  void checkCycle(final object) {
    seen.forEach((Object o) {
      if (identical(o, object)) {
        throw new JsonCyclicError(object.toString());
      }     
    });
    seen.add(object);
  }

  Object scanAndReplaceObject(final object) {
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
          return scanAndReplaceObject(o);
        }).toList(growable:false);
      }
      seen.remove(object);
      return object;
    } else if (object is Map) {
      checkCycle(object);
      Map<String, Object> m = object;
      
      m.keys.forEach((String key) {
        if (key is String) {
          m[key] = scanAndReplaceObject(m[key]);
        } else {
          throw new NotSerializableObjectException("Key must be string.");
        }
      });
      seen.remove(object);
      return object;
    } else if (object is SendPort) {
      return new _LocalIsolate(object).toRemoteSendPort();
    } else {
      checkCycle(object);
      var r = scanAndReplaceObject(object.toJson());
      seen.remove(object);
      return r;
    }
  }
}
