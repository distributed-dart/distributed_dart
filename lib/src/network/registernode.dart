import 'dart:io';

// throw error if someone tries to access it before it has been initialized
IsolateNode _currentNode;
IsolateNode get currentNode {
  if (currentNode != null)
    throw UnsupportedOperationError("registerNode has not yet been called");
  return _currenNode;
}

/**
 * set location of received .dart files
 * if not intialized, a default directory in a os specific cache folder
 * is returned
 */
Path _workDirPath;
Path get workDir {
  if(_workDirPath != null)
    return _workDirPath;

  Path defaultPath;
  var os = Platform.operatingSystem;

  if ( os  == "macos" || os == "linux"){
    defaultPath = new Path(Platform.environment['HOME']);
    defaultPath = defaultPath.append('.cache/distributed_dart');
  }

  if ( os == "windows"){
    defaultPath = new Path(Platform.environment['LOCALAPPDATA']);
    defaultPath = defaultPath.append('distributed_dart');
  }

  return defaultPath;
}

// Node Identification class
class IsolateNode{
  final String host;
  final int port;
  IsolateNode(this.host, [int port=12345]): this.port = port;
}

bool _registerNodeCalled = false;
void registerNode(IsolateNode node, [bool allowremote=false, Path workdir]){
  if(_registerNodeCalled)
    throw new UnsupportedOperationError("Can only register node once");
  _registerNodeCalled = true;
  _currentNode = node;
  if (workdir != null)  _workDirPath = workdir;

  if(allowremote){
    // start network with isolate spawn handler
    //Network.init();
  } else {
    // start network with isolate without  spawn handler
    //Network.init();
  }
}

