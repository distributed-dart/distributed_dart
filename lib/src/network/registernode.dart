part of distributed_dart;

/**
 * set location of received .dart files
 * if not intialized, a default directory in a os specific cache folder
 * is returned
 */
Path _workDirPath;

void registerNode(NodeAddress node, [bool allowremote=false, Path workdir]) {
  //kregisterNode must not be called more than once
  if( ! NodeAddress._localhost == null){
    throw new UnsupportedOperationError("Can only register node once");
  }

  // set local identification
  NodeAddress._localhost = node;
  
  // set path to where to store received files
  _workDirPath = (workdir == null) ? _getDefaultWorkDir() : workdir;
  
  // setup requesthandlers
  _RequestHandler.allow(_NETWORK_FILE_HANDLER);
  _RequestHandler.allow(_NETWORK_FILE_REQUEST_HANDLER);
  _RequestHandler.allow(_NETWORK_ISOLATE_DATA_HANDLER);
  
  if(allowremote){
    _RequestHandler.allow(_NETWORK_SPAWN_ISOLATE_HANDLER);
  }
  
  // start listening for incomming requests
  Network.initServer();
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

