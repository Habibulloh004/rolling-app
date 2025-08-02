import 'package:hive/hive.dart';

class Maillinglist {
  static final box = Hive.box("maillinglist");

  static subscribe(String v) {
    box.put('maillinglist', v);
  }

  static bool isUserSubscribed() {
    if (box.length == 0) {
      return false;
    } else {
      return true;
    }
  }

  static String getSubscription() {
    return box.get("maillinglist");
  }

  static clear() {
    box.clear();
  }
}
