import 'package:hive/hive.dart';

class MapLocation {
  static final box = Hive.box("map");

  static addLocation(Map data) {
    box.add(data);
  }

  static int getLength() {
    return box.length;
  }

  static Map getLocationAt(int id) {
    return box.getAt(id);
  }

  static deleteAt(int id) {
    box.deleteAt(id);
  }

  static updateAt(int id, Map data) {
    box.put(id, data);
  }

  static bool isNoMaps() {
    if (box.length == 0) {
      return true;
    } else {
      return false;
    }
  }

  static clean() {
    box.clear();
  }
}
