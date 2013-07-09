part of distributed_dart;

// Prefixes a the bytelist object with the size of the json string
// size prefixe is a 64 bit integer, encoded as Uint8List(8)
class _ByteListEncoder extends StreamEventTransformer {
    void handleData (List data, EventSink sink) {
      var size = new Uint8List(8);
      new ByteData.view(size.buffer).setUint64(0,data.length);
      _log("add header: ${data.length} -> $size");
      sink.add(size);
      sink.add(data);
    }
}

// split concatinated objects, or assemble larger objects which has been split 
class _ByteListDecoder extends StreamEventTransformer {
  static const int PKG_SIZE_LENGTH = 8; // 64 bit = 8x8 bits
  
  int remaining = -1;
  List<int> obj = [];
  List<int> sizeBuffer = null;
  
  void handleData(Uint8List data,EventSink<List<int>> sink) {
    var idx = 0;
    
    _log("received ${data.length} bytes");
    
    while (idx < data.length) {
      int data_remaining = (data.length - idx);
      
      // prepare to read a new object
      if(remaining == -1) {
        if (sizeBuffer != null) {
          // We did not got all data to get the package size from last time we 
          // run handleData. Therefore we now try get the missing parts of the 
          // length.
          
          // Data we need to get the package size.
          int neededData = (PKG_SIZE_LENGTH - sizeBuffer.length);
          
          if (data_remaining < neededData) {
            // Well this should never happen but sometimes it is possible to
            // get unlucky. In this case we recieve a package there are too
            // small to contain the remaining of the package size.
            
            sizeBuffer.addAll(data.getRange(idx, data.length-1));
            
            if (logging) {
              var header = _Uint8ListToBinaryString(sizeBuffer);
              _log(" > unfinished header. Waiting for the rest: $header");  
            }
            
            break; // Wait for next network package
          } else {
            // We recieve enough data to get the package size.
            
            sizeBuffer.addAll(data.getRange(idx, idx+neededData));
            
            var sizeAsUint8List = new Uint8List.fromList(sizeBuffer);
            var byteDataView = new ByteData.view(sizeAsUint8List.buffer);
            
            remaining = byteDataView.getUint64(idx);
            idx+=neededData;
            
            if (logging) {
              var headerString = _Uint8ListToBinaryString(sizeBuffer);
              _log(" > header: $headerString -> size: $remaining bytes");  
            }
          }
        } else {
          // This is first try to get the package size from data.
          
          if (data_remaining < PKG_SIZE_LENGTH) {
            // Well, there are not enough space left in the network package to
            // contain the package size. We create a new buffer and wait for 
            // rest to get the package size.
            
            sizeBuffer = new List();
            sizeBuffer.addAll(data.getRange(idx, data.length-1));
            
            if (logging) {
              var header = _Uint8ListToBinaryString(sizeBuffer);
              _log(" > unfinished header. Waiting for the rest: $header");  
            }
            
            break; // Wait for next network package
          } else {
            // There are enough data to get the package size.
            
            var byteDataView = new ByteData.view(data.buffer);
            
            remaining = byteDataView.getUint64(idx);
            idx+=PKG_SIZE_LENGTH;
            
            if (logging) {
              var header = data.sublist(idx-PKG_SIZE_LENGTH,idx);
              var headerString = _Uint8ListToBinaryString(header);
              _log(" > header: $headerString -> size: $remaining bytes");  
            }
          }
        }
      }

      List objpart;
      
      if (data_remaining < remaining) {
        objpart = data.sublist(idx); // sublist from index to end
      } else {
        objpart = data.sublist(idx,idx+remaining);
      }
      
      remaining -= objpart.length;
      idx += objpart.length;
      obj.addAll(objpart);
      _log(" > read ${objpart.length} bytes");

      // object is assembled, write to sink, and mark that we are ready to
      // read the next object.
      if (remaining == 0) {
        sink.add(obj);
        remaining = -1;
        obj = new List();
        _log(" > done: total ${obj.length} bytes");
      }
    }
  }
}

class _JsonEncoder extends StreamEventTransformer <dynamic,String> {
  void handleData(dynamic data, EventSink<String> sink){
    try {
      sink.add(json.stringify(data));
    } catch (e){
      _err(e);
    }
  }
}

class _JsonDecoder extends StreamEventTransformer<String, dynamic> {
  void handleData(String data, EventSink<dynamic> sink){
    sink.add(json.parse(data));
  }
}

/**
 * Scans objects, for SendPort and _RemoteSendPorts, and rewrites them
 * Used to support embedding SendPorts inside the payload of a message.
 */
class _ObjectScanner {
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
      return a;
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
