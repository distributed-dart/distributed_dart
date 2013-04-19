part of distributed_dart;

class DartCode {
  String name = "libname";
  String hash = "7576f7rd";
  String basedir = "/path/to/library";
  Map<String,String> files = { 
    '657de657f' : 'src/somefile.dart', 
    '6579e43f' : 'src/module/anotherfile.dart'
  };
  DartCode(this.name, this.hash, this.basedir, this.files);
  DartCode._dummy();
}

class SourceLibrary{
  static Future<DartCode> lookup({String uri, String hash}){
    return new Future.value(new DartCode._dummy());
  }
}



