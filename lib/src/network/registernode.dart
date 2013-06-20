IsolateNode _currentNode;

// Node Identification class
class IsolateNode{
  final String host;
  final int port;
  IsolateNode(this.host, [int port=12345]): this.port = port;
}

void registerNode(IsolateNode node, {bool allowRemoteIsolates}){
  _currentNode = node;

  if(allowRemoteIsolates){
    // start network with isolate spawn handler
  } else {
    // start network with isolate without  spawn handler
  }
}

//main(){
//  registerNode(new IsolateNode("123.123.123"), allowRemoteIsolates:true);
//}
