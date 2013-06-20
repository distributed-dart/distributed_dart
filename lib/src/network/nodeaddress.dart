part of distributed_dart;

/**
 * Add something here.
 */
class NodeAddress {
  static const _HOST = "host";
  static const _PORT = "port";
  
  final String host;
  final int port;
  
  const NodeAddress(this.host, [this.port=12345]);
  
  factory NodeAddress.fromJsonMap(Map jsonMap) {
    return new NodeAddress(jsonMap[_HOST], jsonMap[_PORT]);
  }
  
  String toString() => "$host:$port";
  
  Map<String,dynamic> toJson() {
    var map = new Map();
    
    map[_HOST] = host;
    map[_PORT] = port;
    
    return map;
  }
}
