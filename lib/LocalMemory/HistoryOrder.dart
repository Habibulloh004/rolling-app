import 'package:hive/hive.dart';

class HistoryOrder {
  static final box = Hive.box("historyOrder");

  static addHistoryOrder(Map data) {
    box.add(data);
  }

  static Map getHistoryOrder(int id) {
    return box.get(id);
  }

  static List getReversedHistoryOrder() {
    List reversedItems = box.values.toList().reversed.toList();
    return reversedItems;
  }

  static List getHistoryOrderProducts(int id) {
    return box.get(id)['products'];
  }

  static int getLength() {
    return box.length;
  }

  static clear() {
    box.clear();
  }
}
