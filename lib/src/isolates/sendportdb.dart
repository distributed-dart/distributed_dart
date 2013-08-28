part of distributed_dart;

class _SendPortDb {
  static Map<_RemoteSendPort,SendPort> remoteToPort = new Map();
  static Map<SendPort,_RemoteSendPort> portToRemote = new Map();
  
  static add(SendPort sp, _RemoteSendPort rsp) {
    _log("_SendPortDb: add add(${sp.toString()}, ");
    _log("     ID: ${rsp.id}");
    _log("     NodeAdress: ${rsp.node})");
    
    remoteToPort[rsp] = sp;
    portToRemote[sp] = rsp;
    
    _log("_SendPortDb: Size of remoteToPort: ${remoteToPort.length}");
    _log("_SendPortDb: Size of portToRemote: ${portToRemote.length}");
  }
  
  static getRemoteSendPort(SendPort sp) {
    _log("_SendPortDb: getRemoteSendPort(${sp.toString()})");
    return portToRemote[sp];
  }
  
  static getSendPort(_RemoteSendPort rsp) {
    _log("_SendPortDb: getSendPort for _RemoteSendPort:");
    _log("     ID: ${rsp.id}");
    _log("     NodeAdress: ${rsp.node}");
    return remoteToPort[rsp];
  }
}
