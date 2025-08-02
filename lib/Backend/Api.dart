import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:sushi_alpha_project/LocalMemory/CreditCard.dart';

import '../Consts/Functions.dart';
import '../LocalMemory/User.dart';
import '../Models/Categories.dart';
import '../Models/Product.dart';

class Api {
  static final dio = Dio();

  static Future<List<Categories>> getCategories() async {
    //create list
    List<Categories> categories = [];
    try {
      final response = await dio.get(
          'https://rolling-sushi.joinposter.com/api/menu.getCategories?token=046902:6281755091471320780488d484cc4b78');
      final data = response.data['response'];

      if (response.data['error'] == null) {
        for (int i = 0; i < data.length; i++) {
          if (data[i]['visible'][0]["visible"] == 1) {
            categories.add(Categories(
              name: data[i]["category_name"],
              categoryId: data[i]["category_id"].toString(),
              photo:
                  "https://rolling-sushi.joinposter.com${data[i]["category_photo"].toString()}",
            ));
          } else {
            continue;
          }
        }
      } else {
        // show error
      }

      return categories;
    } catch (e) {
      print("some kind off error happende while connection");
      debugPrint(e.toString());
    }
    return [];
  }

  static Future<List<Product>> getProducts(String id) async {
    List<Product> products = [];
    try {
      print(id);
      final response = await dio.get(
          'https://rolling-sushi.joinposter.com/api/menu.getProducts?token=046902:6281755091471320780488d484cc4b78&category_id=${id}');
      final data = response.data['response'];
      print(data);

      if (response.data['error'] == null) {
        for (int i = 0; i < data.length; i++) {
          print("----------------");
          print(data[i]['hidden'] == "0");
          if (data[i]['spots'][0]["visible"] == "1") {
            String ingredientsString = "";
            var ingredients = data[i]["ingredients"];
            if (ingredients == null) {
              ingredientsString = "";
            } else {
              for (int j = 0; j < ingredients.length; j++) {
                ingredientsString += "${ingredients[j]["ingredient_name"]}g \n";
              }
            }

            var descriptionOrg = data[i]["product_production_description"];
            String descriptionClear = "";
            if (descriptionOrg == null) {
              descriptionClear = "";
              print(descriptionClear);
            } else {
              descriptionClear = descriptionOrg.replaceAll('\n', '');
            }

            String numberStr = data[i]["price"]["1"].toString();

            // Removing the last two characters ("00") from the string

            print("*************");
            // print(numberStrTrimmed.length);

            String priceResult = " ";
            print(numberStr.length);

            if (numberStr.length == 7 ||
                numberStr.length == 8 ||
                numberStr.length == 6 ||
                numberStr.length == 5) {
              String numberStrTrimmed =
                  numberStr.substring(0, numberStr.length - 2);
              priceResult =
                  numberStrTrimmed.substring(0, numberStrTrimmed.length - 3) +
                      " " +
                      numberStrTrimmed.substring(numberStrTrimmed.length - 3);
            } else if (numberStr.length == 1) {
              priceResult = "0";
            }

            products.add(Product(
                photo:
                    "https://rolling-sushi.joinposter.com${data[i]["photo_origin"]}",
                name: data[i]["product_name"],
                description: descriptionClear,
                ingredients: ingredientsString,
                price: priceResult,
                weight: data[i]["out"].toString() == null
                    ? ""
                    : data[i]["out"].toString(),
                productId: data[i]["product_id"].toString()));
          } else {
            continue;
          }
        }

        return products;
      } else {}
    } catch (e) {
      print("some kind off error happende while connection");
      debugPrint(e.toString());
    }
    return [];
  }

  static sendSms(String code, String phoneNumber) async {
    print(code);

    String modifiedPhoneNumber = phoneNumber.replaceAll("+", "");
    //Rolling Sushi: Ilovamizda ro'yxatdan o'tkaningiz uchun minnatdorchilik bildiramiz. Tasdiqlash uchun kod: %d
    try {
      var data = {
        'phone': modifiedPhoneNumber,
        'message':
            "Rolling Sushi: Ilovamizda ro'yxatdan o'tkaningiz uchun minnatdorchilik bildiramiz. Tasdiqlash uchun kod: ${code}",
      };

      print(data);
      Response response = await dio
          .post('https://vm4983125.25ssd.had.wf:5000/send_sms', data: data);
      print(response.data);
    } catch (e) {
      print(e);
    }
  }

  static Future<Map> createClient(Map data) async {
    try {
      print('inside the api');
      print(data);
      Response response = await dio.post(
          'https://rolling-sushi.joinposter.com/api/clients.createClient?token=046902:6281755091471320780488d484cc4b78',
          data: data);
      if (response.data['response'] != null) {
        Map data = {
          'res': true,
          'id': response.data['response'],
        };

        return data;
      } else if (response.data['error'] == 167) {
        return {
          'res': false,
          'message': "Номер занят",
        };
      } else {
        return {
          'res': false,
          'message': "Что-то пошло не так",
        };
      }
    } catch (e) {
      print(e);
    }
    return {
      'res': false,
      'message': "Что-то пошло не так",
    };
  }

  static Future<Map> getClient(String phone, String password) async {
    String modifiedPhoneNumber = phone.replaceAll("+", "");
    try {
      final response = await dio.get(
          'https://vm4983125.25ssd.had.wf:5000/get_client/${modifiedPhoneNumber}');
      print("--------------");
      print(response.data['comment']);
      Map data = jsonDecode(response.data['comment']);
      String passwodDb = data['password'].replaceAll(RegExp(r'\D'), '');

      print(password);
      if (response.data != " ") {
        // works
        if (passwodDb == password) {
          Map data = {
            'res': true,
            'name': response.data['lastname'],
            'phone': phone,
            'id': response.data['client_id'],
            'password': passwodDb,
            'client_sex': response.data['client_sex'],
            'birthday': response.data['birthday']
          };

          return data;
        } else {
          return {
            'res': false,
            'message': "Введен неверный пароль",
          };
        }
      } else {
        return {'res': false, 'message': "Неверный номер"};
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return {'res': false, 'message': "Неверный номер"};
  }

  static Future<Map> getClientOtp(String phone) async {
    String modifiedPhoneNumber = phone.replaceAll("+", "");
    try {
      final response = await dio.get(
          'https://vm4983125.25ssd.had.wf:5000/get_client/${modifiedPhoneNumber}');
      String passwodDb = response.data['comment'].replaceAll(RegExp(r'\D'), '');

      print("DENDENDEN");
      print(response.data['client_sex']);
      print(response.data['birthday']);

      Map data = {
        'res': true,
        'name': response.data['lastname'],
        'phone': phone,
        'id': response.data['client_id'],
        'password': passwodDb,
      };

      return data;
    } catch (e) {
      print("Error in getClient");
      debugPrint(e.toString());
    }
    return {'res': false, 'message': "incorrect number"};
  }

  static updateUserName(String name) async {
    try {
      Map data = {
        'client_id': User.getUserInfo("id"),
        'client_name': name,
      };

      Response response = await dio.post(
          'https://rolling-sushi.joinposter.com/api/clients.updateClient?token=046902:6281755091471320780488d484cc4b78',
          data: data);
      print(response);
    } catch (e) {
      print(e);
    }
  }

  static updateUserAge(String birthday) async {
    try {
      Map data = {
        'client_id': User.getUserInfo("id"),
        'birthday': birthday,
      };

      Response response = await dio.post(
          'https://rolling-sushi.joinposter.com/api/clients.updateClient?token=046902:6281755091471320780488d484cc4b78',
          data: data);
      print(response);
    } catch (e) {
      print(e);
    }
  }

  static updateUserGender(int gender) async {
    try {
      Map data = {
        'client_id': User.getUserInfo("id"),
        'client_sex': gender,
      };

      Response response = await dio.post(
          'https://rolling-sushi.joinposter.com/api/clients.updateClient?token=046902:6281755091471320780488d484cc4b78',
          data: data);
      print(response);
    } catch (e) {
      print(e);
    }
  }

  //updateUserGender

  static Future<String> giveOrder(Map data) async {
    print('Order data');
    print(data);

    try {
      Response response = await dio
          .post('https://vm4983125.25ssd.had.wf:5000/add_order', data: data);
      print(response.data);
      print(response.data['order_id'].toString());
      return response.data['order_id'].toString();
    } catch (e) {
      print(e);
    }
    return "error";
  }

  static updateGroupsIdUser(int number) async {
    try {
      Map data = {
        'client_id': User.getUserInfo("id"),
        'client_groups_id_client': number.toString(),
      };

      Response response = await dio.post(
          'https://rolling-sushi.joinposter.com/api/clients.updateClient?token=046902:6281755091471320780488d484cc4b78',
          data: data);
    } catch (e) {
      print(e);
    }
  }

  static Future<Map> getUserBonus() async {
    String result = "";
    try {
      print(User.getUserInfo('id'));
      final response = await dio.get(
          'https://vm4983125.25ssd.had.wf:5000/get_bonus/${User.getUserInfo('id').toString()}');
      result = response.data['bonus_value'];
      print("-----------");
      print(result);

      String numberStrTrimmed = '0';
      String priceResult = '0';

      print(result.runtimeType);

      if (int.parse(result) > 0) {
        numberStrTrimmed = result.substring(0, result.length - 2);

        priceResult =
            numberStrTrimmed.substring(0, numberStrTrimmed.length - 3) +
                " " +
                numberStrTrimmed.substring(numberStrTrimmed.length - 3);
      }

      print(numberStrTrimmed);
      print(priceResult);

      return {
        'string': priceResult,
        'int': int.parse(numberStrTrimmed),
      };
    } catch (e) {
      print(e);
    }
    return {
      'string': 'что-то пошло не так',
    };
  }

  static Future<List<Product>> seorchProduct(String name) async {
    List<Product> products = [];
    try {
      final response = await dio
          .get('https://vm4983125.25ssd.had.wf:5000/get_product?name=${name}');
      // print(response);
      final data = response.data;
      print(data);

      for (int i = 0; i < data.length; i++) {
        print(data[i]['name']);
        String ingredientsString = "";
        var ingredients = data[i]["ingredients"];
        if (ingredients == null) {
          ingredientsString = "";
        } else {
          for (int j = 0; j < ingredients.length; j++) {
            ingredientsString += "${ingredients[j]["ingredient_name"]}g \n";
          }
        }

        var descriptionOrg = data[i]["product_production_description"];
        String descriptionClear = "";
        print(descriptionOrg == null);
        if (descriptionOrg == null) {
          descriptionClear = "";
          print(descriptionClear);
        } else {
          descriptionClear = descriptionOrg.replaceAll('\n', '');
        }

        String numberStr = data[i]["price"]["1"].toString();

        // Removing the last two characters ("00") from the string
        String numberStrTrimmed = numberStr.substring(0, numberStr.length - 2);

        String priceResult =
            numberStrTrimmed.substring(0, numberStrTrimmed.length - 3) +
                " " +
                numberStrTrimmed.substring(numberStrTrimmed.length - 3);

        products.add(Product(
            photo: "https://rolling-sushi.joinposter.com${data[i]["photo"]}",
            name: data[i]["product_name"],
            description: descriptionClear,
            ingredients: ingredientsString,
            price: priceResult,
            weight: data[i]["out"].toString() == null
                ? ""
                : data[i]["out"].toString(),
            productId: data[i]["product_id"].toString()));
      }

      return products;
    } catch (e) {
      print('Errro in seorch');
    }
    return [];
  }

  static Future<String> getOrderState(String id) async {
    try {
      final response =
          await dio.get('https://vm4983125.25ssd.had.wf:5000/get_order/${id}');

      // return "cooking";
      return response.data['status'];
    } catch (e) {
      debugPrint(e.toString());
    }
    return '404';
  }

  static Future<bool> isFirstDiscountExist() async {
    try {
      String phone = User.getUserInfo("phone");
      String modifiedPhoneNumber = phone.replaceAll("+", "");
      final response = await dio.get(
          'https://vm4983125.25ssd.had.wf:5000/get_client/${modifiedPhoneNumber}');
      Map data = jsonDecode(response.data['comment']);

      if (data['length'] == '0') {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint(e.toString());
    }

    return false;
  }

  static Future<String> getOrderLengthPoster() async {
    try {
      String phone = User.getUserInfo("phone");
      String modifiedPhoneNumber = phone.replaceAll("+", "");
      final response = await dio.get(
          'https://vm4983125.25ssd.had.wf:5000/get_client/${modifiedPhoneNumber}');
      Map data = jsonDecode(response.data['comment']);

      return data['length'];
    } catch (e) {
      debugPrint(e.toString());
    }

    return "Some thing went wrong";
  }

  static setOrderLengthPoster(String number) async {
    try {
      Map comment = {
        'password': 'password ${User.getUserInfo('password')}',
        'length': number,
      };

      String json = jsonEncode(comment);

      Map data = {
        'client_id': User.getUserInfo("id"),
        'comment': json,
      };

      Response response = await dio.post(
          'https://rolling-sushi.joinposter.com/api/clients.updateClient?token=046902:6281755091471320780488d484cc4b78',
          data: data);
      print(response);
    } catch (e) {
      print(e);
    }
  }

  static Future<Map<String, String>> payCreditCard(int amount) async {
    try {
      String formattedDate =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      String uniqString =
          formattedDate + " " + User.getUserInfo('phone').toString();
      String cardNumberWithoutSpaces =
          await CreditCard.getCreditCardNumber().replaceAll(' ', '');
      String creditCardDate = transformDate(CreditCard.getCreditCardDate());

      Map data = {
        "cardNumber": cardNumberWithoutSpaces,
        'expireDate': creditCardDate,
        'amount': amount,
        'extraId': uniqString,
      };

      print(data);

      Response response = await dio.post(
        'https://vm4983125.25ssd.had.wf:5000/pay',
        data: data,
      );

      print(response);
      if (response.data['error'] == null) {
        print(response.data['result']['session']);
        return {
          'status': 'success',
          'session': response.data['result']['session'].toString(),
        };
      } else {
        return {
          'status': 'failed',
        };
      }
    } catch (e) {
      print(e);
    }
    return {
      'status': 'failed',
    };
  }

  static Future<Map<String, String>> paymentConfermationCreditCard(
      String session, String otp) async {
    try {
      Map data = {
        "session": int.parse(session),
        'otp': otp,
      };

      Response response = await dio.post(
        'https://vm4983125.25ssd.had.wf:5000/pay_confirm',
        data: data,
      );

      print(response);
      if (response.data['error'] == null) {
        return {
          'status': 'success',
        };
      } else {
        return {
          'status': 'failed',
        };
      }
    } catch (e) {
      print(e);
    }
    return {
      'status': 'failed',
    };
  }

  static Future<bool> isRestaurantOpen() async {
    bool allowed = false;
    try {
      final response =
          await dio.get("https://sushiserver.onrender.com/get_time");

      List<String> closeParts = response.data['closed_time'].split(':');
      int closingHour = int.parse(closeParts[0]);

      List<String> openParts = response.data['opened_time'].split(':');
      int openHour = int.parse(openParts[0]);

      int currentHour = DateTime.now().hour;

      if (currentHour >= openHour && currentHour < closingHour) {
        allowed = true;
      }

      print(allowed);
      return allowed;
    } catch (e) {
      print(e);
    }
    return allowed;
  }

  static Future<int> getDeliveryPrice() async {
    try {
      final response =
          await dio.get('https://vm4983125.25ssd.had.wf:5000/delivery_price');

      if (response.statusCode == 200 &&
          response.data != null &&
          response.data is Map) {
        // print(response.data);
        int price = response.data['delivery_price'];
        if (price != null) {
          return price;
        } else {
          throw Exception('Delivery price not found in response.');
        }
      } else {
        throw Exception(
            'Failed to fetch delivery price or unexpected response format.');
      }
    } catch (e) {
      debugPrint('Error fetching delivery price: ${e.toString()}');
      return 1; // Consider a better fallback value or propagate the error as needed.
    }
  }

  static Future<List> getMailingList() async {
    try {
      final response =
          await dio.get("https://sushiserver.onrender.com/getNews");

      print(response.data);

      return response.data;
    } catch (e) {
      debugPrint('Error fetching delivery price: ${e.toString()}');
      return []; // Consider a better fallback value or propagate the error as needed.
    }
  }

  static sendFeedback(String orderId, String data) async {
    try {
      final response = await dio.put(
          "https://vm4983125.25ssd.had.wf:5000/update_order_feedback/${orderId}",
          data: data);

      print(response.data);
    } catch (e) {
      debugPrint(
          'Error fetching delivery price: ${e.toString()}'); // Consider a better fallback value or propagate the error as needed.
    }
  }
}
