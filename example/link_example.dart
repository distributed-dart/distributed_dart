import "dart:io";
import "dart:async";

void main() {
  Path destination = new Path("example/link_example.link.dart");
  Path source = new Path("example/link_example.dart");
  
  List<String> arguments = ["/C", 
                            "mklink", 
                            "/H", 
                            destination.toNativePath(), 
                            source.toNativePath()];
  
  Future<ProcessResult> result = Process.run("cmd", arguments);
  
  result.then((ProcessResult result) {
    print("stdout: ${result.stdout}");
    print("stderr: ${result.stderr}");
    
    if (result.stderr.isEmpty) {
      print("Try delete link.");
      new File.fromPath(destination).delete().then((_)=>print("Link deleted"));
    }
  });
}
