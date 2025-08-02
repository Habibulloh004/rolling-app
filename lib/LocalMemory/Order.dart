import 'package:hive/hive.dart';

class Order {
  static final box = Hive.box("order");

  static setOrder(String id, Map data) {
    box.put(id, data);
  }

  static deleteOrder(String id) {
    box.delete(id);
  }

  static deleteOrderAt(int id) {
    box.deleteAt(id);
  }

  static Map getOrder(String id) {
    return box.get(id);
  }

  static Map getOrderAt(int id) {
    return box.getAt(id);
  }

  static int getOrderLength() {
    return box.length;
  }

  static bool isInOrder(String id) {
    if (box.get(id) != null) {
      return true;
    }
    return false;
  }

  static Map getOrderPrice() {
    int price = 0;

    print(Order.getOrderLength());
    for (int i = 0; i < Order.getOrderLength(); i++) {
      Map order = Order.getOrderAt(i);
      String priceString = order['price'];

      if (priceString.length == 0) {
      } else {
        int priceResult = int.parse(priceString.replaceAll(" ", ""));

        int amount = int.parse(order["amount"]);

        price += amount * priceResult;
      }
    }

    String numberStrTrimmed = price.toString();
    String result = "0";
    if (numberStrTrimmed.length != 1) {
      result = numberStrTrimmed.substring(0, numberStrTrimmed.length - 3) +
          " " +
          numberStrTrimmed.substring(numberStrTrimmed.length - 3);
    }

    print(result);
    print(price);
    return {
      'string': result,
      'int': price,
    };
  }

  static Map getOrderPriceWithBonus(int bonus) {
    int price = 0;

    // Calculate the total price of all orders
    for (int i = 0; i < Order.getOrderLength(); i++) {
      Map order = Order.getOrderAt(i);

      // Handle price parsing and remove spaces
      String priceString = order['price'].replaceAll(" ", "");
      int priceResult;

      // Error handling in case priceString is not a valid integer
      try {
        priceResult = int.parse(priceString);
      } catch (e) {
        throw Exception('Invalid price format for order: $priceString');
      }

      // Parse the amount
      int amount;
      try {
        amount = int.parse(order['amount']);
      } catch (e) {
        throw Exception('Invalid amount format for order: ${order['amount']}');
      }

      price += amount * priceResult;
    }

    // Subtract the bonus
    price -= bonus;

    // Convert the price to a string for further manipulation
    String numberStrTrimmed = price.toString();

    String result;
    // Add a space between thousands only if price >= 1000
    if (numberStrTrimmed.length > 3) {
      result = numberStrTrimmed.substring(0, numberStrTrimmed.length - 3) +
          " " +
          numberStrTrimmed.substring(numberStrTrimmed.length - 3);
    } else {
      result = numberStrTrimmed;
    }

    return {
      'string': result,
      'int': price,
    };
  }

  static Map getOrderPriceWithDeliveryAndBonus(int bonus) {
    int price = 0;

    for (int i = 0; i < Order.getOrderLength(); i++) {
      Map order = Order.getOrderAt(i);

      String priceString = order['price'];
      int priceResult = int.parse(priceString.replaceAll(" ", ""));

      int amount = int.parse(order["amount"]);

      price += amount * priceResult;
    }

    // delivary price
    price += 10000;
    price -= bonus;

    String numberStrTrimmed = price.toString();
    // giving space "
    String result = numberStrTrimmed.substring(0, numberStrTrimmed.length - 3) +
        " " +
        numberStrTrimmed.substring(numberStrTrimmed.length - 3);

    return {
      'string': result,
      'int': price,
    };
  }

  static Map getOrderPriceWithDelivery() {
    int price = 0;

    for (int i = 0; i < Order.getOrderLength(); i++) {
      Map order = Order.getOrderAt(i);

      String priceString = order['price'];
      int priceResult = int.parse(priceString.replaceAll(" ", ""));

      int amount = int.parse(order["amount"]);

      price += amount * priceResult;
    }

    // delivary price
    price += 10000;

    String numberStrTrimmed = price.toString();
    // giving space "
    String result = numberStrTrimmed.substring(0, numberStrTrimmed.length - 3) +
        " " +
        numberStrTrimmed.substring(numberStrTrimmed.length - 3);

    return {
      'string': result,
      'int': price,
    };
    ;
  }

  static List<Map> getFullOrder() {
    List<Map> result = [];

    for (int i = 0; i < getOrderLength(); i++) {
      result.add(getOrderAt(i));
    }
    return result;
  }

  static List getOrderAmountAndId() {
    List result = [];

    for (int i = 0; i < getOrderLength(); i++) {
      result.add({
        'product_id': getOrderAt(i)['productId'],
        'amount': getOrderAt(i)['amount'],
      });
    }

    return result;
  }

  static bool isNoOrder() {
    if (box.length == 0) {
      return true;
    } else {
      return false;
    }
  }

  static clearOrder() {
    box.clear();
  }
}
