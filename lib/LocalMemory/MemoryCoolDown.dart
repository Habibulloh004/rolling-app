import 'package:hive/hive.dart';

class Memorycooldown {
  static final box = Hive.box("memorycooldown");

  // Store the last update date
  static void setDate(String data) {
    box.put("date", data);
  }

  static String? getDate() {
    return box.get("date");
  }

  // Check if a cooldown record exists
  static bool isCoolDownExists() {
    return box.containsKey("date");
  }

  // Store the number of changes
  static void setChangeCount(int count) {
    box.put("changeCount", count);
  }

  static int getChangeCount() {
    return box.get("changeCount", defaultValue: 0);
  }

  static void incrementChangeCount() {
    int currentCount = getChangeCount();
    setChangeCount(currentCount + 1);
  }

  // Reset the cooldown data
  static void clean() {
    box.clear();
  }
}
