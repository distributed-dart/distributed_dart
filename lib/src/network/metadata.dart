part of distributed_dart;

class MetadataException implements Exception {
  final String message;
  const MetadataException(this.message);
  String toString() => "MetadataException: $message";
}

class Metadata {
  final String TYPE;
  final Map META;

  Metadata(this.TYPE, this.META);

  // wrap data in metadata layer
  Map apply(dynamic data){
    var m = new Map.from(META);
    m['TYPE'] = TYPE;
    m['DATA'] = data;
    return m;
  }

  static String getType(Map m){
    if(! m.containsKey('TYPE'))
      throw new MetadataException("No type information");
      return  m['TYPE'];
  }

  static dynamic getData(Map m){
    if(! m.containsKey('DATA'))
      throw new MetadataException("No Data");
      return  m['DATA'];
  }
}

// stream transformer, appends metadata to stream
class MetadataEncoder extends StreamEventTransformer<dynamic,Map> {
  Metadata metadata;
  MetadataEncoder(this.metadata) : super();
  void handleData(dynamic data, EventSink<Map> sink){
    sink.add(metadata.apply(data));
  }
}


