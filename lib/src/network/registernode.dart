part of distributed_dart;

// throw error if someone tries to access it before it has been initialized
NodeAddress _currentNode;

/**
 * set location of received .dart files
 * if not intialized, a default directory in a os specific cache folder
 * is returned
 */
Path _workDirPath;

void registerNode(NodeAddress node, [bool allowremote=false, Path workdir]) {
  if(_currentNode != null)
    throw new UnsupportedOperationError("Can only register node once");
  
  _currentNode = node;
  _workDirPath = (workdir == null) ? _getDefaultWorkDir() : workdir;

  if(allowremote){
    // start network with isolate spawn handler
    //Network.init();
  } else {
    // start network with isolate without  spawn handler
    //Network.init();
  }
}

/// Returns a default value for working directory based on running OS.
Path _getDefaultWorkDir() {
  Path defaultPath;

  if (Platform.operatingSystem == "windows"){
    defaultPath = new Path(Platform.environment['LOCALAPPDATA']);
    defaultPath = defaultPath.append('distributed_dart');
  } else {
    defaultPath = new Path(Platform.environment['HOME']);
    defaultPath = defaultPath.append('.cache/distributed_dart');
  }

  return defaultPath;
}

