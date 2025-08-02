import 'package:hive/hive.dart';

class Bonus {
  static final box = Hive.box("bonus");

  static setBonus(String id, Map data) {
    box.put(id, data);
  }

  static getBonus(String id) {
    return box.get(id);
  }

  static bool isBonusExists() {
    if (box.length == 0) {
      return false;
    } else {
      return true;
    }
  }

  static clean() {
    box.clear();
  }
}
