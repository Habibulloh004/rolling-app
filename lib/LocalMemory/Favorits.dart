import 'package:hive/hive.dart';

class Favorites {
  static final box = Hive.box("favorites");

  static setFavorite(String id, Map data) {
    box.put(id, data);
  }

  static deleteFavorite(String id) {
    box.delete(id);
  }

  static bool isInFavorite(String id) {
    if (box.get(id) != null) {
      return true;
    }
    return false;
  }

  static Map getFavoriteAt(int id) {
    return box.getAt(id);
  }

  static Map getFavorite(String id) {
    return box.get(id);
  }

  static int getLengthFavorite() {
    return box.length;
  }

  static clean() {
    box.clear();
  }
}
