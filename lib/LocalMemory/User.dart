import 'package:hive/hive.dart';

class User {
  static final box = Hive.box("user");

  static addUserInfo(String id, String value) {
    box.put(id, value);
  }

  static String getUserInfo(String id) {
    return box.get(id) ?? " ";
  }

  static bool isUserExistsStrict() {
    if (box.length == 0) {
      return true;
    } else {
      return false;
    }
  }

  static bool isUserExists() {
    if (box.length == 0 || box.length == 1) {
      return true;
    } else {
      return false;
    }
  }

  static setLoginRegistrationFromProfile(bool v) {
    box.put('loginRegistration', v);
  }

  static getLoginRegistrationFromProfile() {
    return box.get("loginRegistration");
  }

  static bool isKeyAvalible(String id) {
    return box.containsKey(id);
  }

  static clear() {
    box.clear();
  }
}
