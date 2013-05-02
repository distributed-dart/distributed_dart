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
  list.forEach((int hashValue) => sb.write(hashValue.toRadixString(16)));
  return sb.toString();
}
