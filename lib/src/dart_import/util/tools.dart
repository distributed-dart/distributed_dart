part of distributed_dart;

/**
 * Use to compare each element in two lists. Returns [true] if the two lists
 * is equal size and the elements in the each list is equel:
 */
bool _compareLists(List list1, List list2) {
  if (list1 == null || list2 == null) {
    return false;
  }
  
  if (list1.length != list2.length) {
    return false;
  }
  
  for (int i = 0; i < list1.length; i++) {
    if (list1[i] != list2[i]) {
      return false;
    }
  }
  
  return true;
}

/**
 * Convert a List<int> to a String by read each int and convert to hex values.
 * Useful for convert a checksum to a String.
 */
String _hashListToString(List<int> list) {
  StringBuffer sb = new StringBuffer();
  list.forEach((int hashValue) {
    String radixValue = hashValue.toRadixString(16);
    
    if (radixValue.length == 1) {
      sb.write("0");
    }
    
    sb.write(radixValue);
  });
  return sb.toString();
}

/**
 * Takes the path from the DartCode object and all dependencies and removes
 * unnecessary parts of the path.  E.g.
 * 
 *     C:\Users\Dart\Code\Program.dart
 *     C:\Users\Dart\Code\Packages\important_lib.dart
 *     C:\Users\Dart\Code\Packages\data\model.dart
 *     C:\Users\Dart\Code\Packages\server\database.dart
 * 
 * This will change the paths into:
 * 
 *     Program.dart
 *     Packages\important_lib.dart
 *     Packages\data\model.dart
 *     Packages\server\database.dart
 * 
 * The purpose is to make the paths independent of the running system.
 * 
 * The return value is the number of parts there are deleted from each path.
 */
int _shortenPaths(List<_FileNode> dependencies) {
  if (logging) {
    StringBuffer sb = new StringBuffer("Running _shortenPaths([");
    bool first = true;
    
    dependencies.forEach((_FileNode node) {
      if (first) {
        sb.write("${node.path}");
      } else {
        sb.write(", ${node.path}");
      }
    });
    
    sb.write("])");
    _log(sb.toString());
  }
  
  // Get all segments of all paths in dependencies and this DartCode instance.
  List<List<String>> paths = dependencies.map((_FileNode node) {
    return node.path.segments();
  }).toList(growable: false);
  
  int segmentsToRemove = _countEqualSegments(paths);
  
  dependencies.forEach((_FileNode node) {
    node._path = _removeSegmentsOfPath(node._path, segmentsToRemove);
  });
  
  return segmentsToRemove;
}

/**
 * Find the number of equal segments in a list of segments:
 * 
 *     List1 = [ "c", "Program Files", "Admin" ]
 *     List2 = [ "c", "Users", "Admin", "Test Data" ]
 *     List3 = [ "c", "Users", "Admin" ]
 * 
 * In this example we should return 1 because only 1 segment is equal in all
 * lists. We don't count equal segments after the first found of non-equal
 * list of segments (so "Admin" will not count here").
 */
int _countEqualSegments(List<List<String>> paths) {
  _log("Running _countEqualSegments(");
  paths.forEach((List<String> x) => _log("     $x"));
  _log(");");
  
  int minSegmentLength = paths[0].length;
  
  // Get the size of the shortest list
  paths.forEach((List<String> segments) {
    if (segments.length < minSegmentLength) {
      minSegmentLength = segments.length;
    }
  });
  
  // Find the number of equal segments in a list of segments
  for (int i = 0; i < minSegmentLength; i++) {
    String compareValue = paths[0][i];
    
    for (int k = 0; k < paths.length; k++) {
      if (paths[k][i] != compareValue) {
        _log("Return value for _countEqualSegments() = $i");
        return i;
      }
    }
  }
  
  _log("Return value for _countEqualSegments() = $minSegmentLength");
  return minSegmentLength;
}

/**
 * Removes a number of segments of a given Path and creates a new Path with
 * the rest of segmenst. E.g.:
 * 
 *     Path p = new Path("C:\\User\\Dart\\Programs\\Fun\\main.dart");
 *     p = _removeSegmentsOfPath(p,3);
 *     p == new Path("Programs\\Fun\\main.dart");
 */
Path _removeSegmentsOfPath(Path path, int segmentsToRemove) {
  StringBuffer sb = new StringBuffer();
  List<String> segments = path.segments();
  
  bool first = true;
  
  // Never delete all parts of the part!
  if (segmentsToRemove >= segments.length) {
    segmentsToRemove = segments.length - 1;
  }
  
  segments.skip(segmentsToRemove).forEach((String segment) {
    if (first) {
      first = false;
    } else {
      sb.write("/");
    }
    sb.write(segment);
  });
  
  return new Path(sb.toString());
}
