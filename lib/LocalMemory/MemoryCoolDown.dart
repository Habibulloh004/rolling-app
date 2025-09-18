import 'package:hive/hive.dart';

class Memorycooldown {
  static final box = Hive.box("memorycooldown");

  static setDate(String date) {
    box.put('date', date);
  }

  static String? getDate() {
    return box.get('date');
  }

  static bool isCoolDownExists() {
    return box.containsKey('date');
  }

  static setChangeCount(int count) {
    box.put('changeCount', count);
  }

  static int getChangeCount() {
    return box.get('changeCount') ?? 0;
  }

  static incrementChangeCount() {
    int currentCount = getChangeCount();
    setChangeCount(currentCount + 1);
  }

  static clean() {
    box.clear();
  }
}