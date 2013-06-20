part of distributed_dart;

/**
 * set location of received .dart files
 * if not intialized, a default directory in a os specific cache folder
 * is returned
 */
Path _workDirPath;

void registerNode(NodeAddress node, [bool allowremote=false, Path workdir]) {
  if(NodeAddress._localhost == null)
    NodeAddress._localhost = node;
  else    
    throw new UnsupportedOperationError("Can only register node once");
  

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

