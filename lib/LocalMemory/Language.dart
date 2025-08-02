import 'package:hive/hive.dart';

class Language {
  static final box = Hive.box("language");

  static setLanguage(String v) {
    box.put('language', v);
  }

  static bool isLanguageAvailable() {
    if (box.length == 0) {
      return false;
    } else {
      return true;
    }
  }

  static String getLanguage() {
    return box.get("language");
  }

  static clear() {
    box.clear();
  }
}
