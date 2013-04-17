part of distributed_dart;

class DartCode {
  String name;
  String path;
  String hash;
  List<int> source;
  List<DartCode> dependencies = new List<DartCode>();
  
  String get sourceAsString {
    StringBuffer sb = new StringBuffer();
    dependencies.forEach((e) => sb.writeCharCode(e));
    return sb.toString();
  }
}
