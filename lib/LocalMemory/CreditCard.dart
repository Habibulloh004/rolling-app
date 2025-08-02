import 'package:hive/hive.dart';

class CreditCard {
  static final box = Hive.box("creditCard");

  static bool isCreditCardExists() {
    if (box.length == 0) {
      return true;
    } else {
      return false;
    }
  }

  static setCreditCardNumber(String v) {
    box.put('number', v);
  }

  static String getCreditCardNumber() {
    return box.get("number");
  }

  static setCreditCardName(String v) {
    box.put('name', v);
  }

  static getCreditCardName() {
    return box.get("name");
  }

  static setCreditCardDate(String v) {
    box.put('date', v);
  }

  static getCreditCardDate() {
    return box.get("date");
  }

  static setUserChoseCard() {
    box.put('userChoseCard', true);
  }

  static getUserChoseCard() {
    return box.get('userChoseCard');
  }

  static clearUserChoseCard() {
    box.put('userChoseCard', false);
  }

  static clear() {
    box.clear();
  }
}
