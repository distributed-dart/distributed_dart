part of distributed_dart;

/**
 * Used to compare two lists and return true if all elements in each list is
 * the same and the lists is the same size.
 */
bool _compareLists(List<int> hash1, List<int> hash2) {
  if (hash1 == null || hash2 == null) {
    return false;
  }
  
  if (hash1.length != hash2.length) {
    return false;
  }
  for (int i = 0; i < hash1.length; i++) {
    if (hash1[i] != hash2[i]) {
      return false;
    }
  }
  return true;
}

/**
 * Convert a List<int> to a String by read each int and convert to hex values.
 */
String _hashListToString(List<int> list) {
  StringBuffer sb = new StringBuffer();
  list.forEach((int hashValue) => sb.write(hashValue.toRadixString(16)));
  return sb.toString();
}
