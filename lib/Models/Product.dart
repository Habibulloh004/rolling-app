import 'package:sushi_alpha_project/Consts/Functions.dart';

class Product {
  final String photo;
  final String name;
  final String description;
  final String ingredients;
  final String price;
  final String weight;
  final String productId;

  Product({
    required this.photo,
    required this.name,
    required this.description,
    required this.ingredients,
    required this.price,
    required this.weight,
    required this.productId,
  });

  Map<String, String> getMap() {
    return {
      'photo': photo,
      'name': splitTextFromCategory(description),
      'description': splitText(description),
      'ingredients': ingredients,
      'price': price,
      'weight': weight,
      'productId': productId,
      'amount': "1",
    };
  }
}
