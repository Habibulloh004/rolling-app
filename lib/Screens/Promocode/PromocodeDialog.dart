import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sushi_alpha_project/Consts/Colors.dart';
import '../../Backend/Api.dart';
import '../../LocalMemory/Order.dart';
import '../../LocalMemory/User.dart';
import '../../Models/Promocode.dart';
import '../../Store/PromocodeStore.dart';
import '../../Consts/Functions.dart';

class PromocodeDialog extends StatefulWidget {
  final List<dynamic> promotions;
  final List<dynamic> productsData;
  final List<dynamic> categoriesData;

  const PromocodeDialog({
    Key? key,
    required this.promotions,
    required this.productsData,
    required this.categoriesData,
  }) : super(key: key);

  @override
  State<PromocodeDialog> createState() => _PromocodeDialogState();
}

class _PromocodeDialogState extends State<PromocodeDialog> {
  final TextEditingController promoCodeController = TextEditingController();
  final PromocodeStore promocodeStore = Get.find<PromocodeStore>();
  String? errorMessage;
  double promotionPrice = 0;
  double promotionDiscount = 0;
  bool isLoading = false;

  void handleRemovePromo() {
    // Call the correct method name from PromocodeStore
    promocodeStore.handleRemovePromo();
    promoCodeController.clear();

    // Clear local state
    setState(() {
      promotionPrice = 0;
      promotionDiscount = 0;
    });

    Get.back(result: 'removed');
    Get.snackbar(
      'Успешно',
      'Промокод удален',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  Future<void> handleApply() async {
    final promoCode = promoCodeController.text.trim();

    if (promoCode.isEmpty) {
      setState(() {
        errorMessage = 'Пожалуйста, введите промокод';
      });
      return;
    }

    if (promocodeStore.activePromocode.value != null) {
      setState(() {
        errorMessage = 'Промокод уже используется';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Get promotions data properly
      List<dynamic> promotionsList = [];

      if (widget.promotions is Map && (widget.promotions as Map)['response'] != null) {
        promotionsList = (widget.promotions as Map)['response'];
      } else if (widget.promotions is List) {
        promotionsList = widget.promotions;
      } else {
        promotionsList = [widget.promotions];
      }

      // Find matching promotion
      final findPromo = promotionsList.firstWhere(
            (promo) {
          if (promo == null) return false;

          final promoName = promo['name']?.toString() ?? '';

          // Extract promo code from name (format: "Description $CODE")
          String promoCodeFromName = '';
          if (promoName.contains('\$')) {
            final parts = promoName.split('\$');
            if (parts.length > 1) {
              promoCodeFromName = parts[1].trim();
            }
          }

          return promoCodeFromName.toLowerCase() == promoCode.toLowerCase();
        },
        orElse: () => null,
      );

      if (findPromo == null) {
        setState(() {
          errorMessage = 'Недействительный промокод';
          isLoading = false;
        });
        return;
      }

      final promocode = Promocode.fromJson(findPromo);

      // Check if auth is required
      if (promocode.params?.clientsType == 3 && !User.isKeyAvalible('id')) {
        setState(() {
          errorMessage = 'Необходима авторизация для использования этого промокода';
          isLoading = false;
        });
        return;
      }

      // Validate conditions
      bool isValid = await validatePromocodeConditions(promocode);

      if (!isValid) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Apply promocode based on type
      await applyPromocode(promocode);

      setState(() {
        isLoading = false;
      });

      Get.back(result: 'applied'); // Return result to refresh basket
      Get.snackbar(
        'Успешно',
        'Промокод применен',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

    } catch (e) {
      print('Error applying promocode: $e');
      setState(() {
        errorMessage = 'Произошла ошибка при применении промокода';
        isLoading = false;
      });
    }
  }

  Future<bool> validatePromocodeConditions(Promocode promocode) async {
    final conditions = promocode.params?.conditions ?? [];
    final totalSum = Order.getOrderPrice()['int'] ?? 0;

    for (final condition in conditions) {
      switch (condition.type) {
        case 0: // All products
          final requiredSum = (condition.sum ?? 0) ~/ 100; // Convert from kopecks to sums
          if (totalSum < requiredSum) {
            setState(() {
              errorMessage = 'Минимальная сумма заказа: ${makePriceSomString(requiredSum)} сум';
            });
            return false;
          }
          break;

        case 1: // Category
          final categoryProducts = Order.getFullOrder().where((order) {
            final product = widget.productsData.firstWhere(
                  (p) => p['product_id'].toString() == order['productId'],
              orElse: () => null,
            );
            return product != null &&
                product['menu_category_id'].toString() == condition.id;
          }).toList();

          if (categoryProducts.isEmpty) {
            final category = widget.categoriesData.firstWhere(
                  (c) => c['category_id'].toString() == condition.id,
              orElse: () => null,
            );
            final categoryName = category != null
                ? splitText(category['category_name'])
                : 'категории';
            setState(() {
              errorMessage = 'Добавьте продукты из $categoryName';
            });
            return false;
          }
          break;

        case 2: // Specific product
          final hasProduct = Order.isInOrder(condition.id ?? '');
          if (!hasProduct) {
            final product = widget.productsData.firstWhere(
                  (p) => p['product_id'].toString() == condition.id,
              orElse: () => null,
            );
            final productName = product != null
                ? product['product_name']
                : 'продукт';
            setState(() {
              errorMessage = 'Добавьте $productName в корзину';
            });
            return false;
          }
          break;
      }
    }

    return true;
  }

  Future<void> applyPromocode(Promocode promocode) async {
    // promocodeStore.setPromocode(promocode);

    switch (promocode.params?.resultType) {
      case 1: // Bonus products
        final bonusProductIds = promocode.params?.bonusProducts ?? [];

        for (final bonusProduct in bonusProductIds) {
          final productData = widget.productsData.firstWhere(
                (p) => p['product_id'].toString() == bonusProduct.id,
            orElse: () => null,
          );

          if (productData != null) {
            // Add to order using your existing Order class
            Map<String, dynamic> orderData = {
              'productId': productData['product_id'].toString(),
              'name': productData['product_name'] ?? '',
              'description': productData['product_production_description'] ?? '',
              'ingredients': '',
              'price': '0', // Bonus product is free
              'weight': productData['out']?.toString() ?? '',
              'photo': productData['photo_origin'] != null
                  ? "https://rolling-sushi.joinposter.com${productData['photo_origin']}"
                  : '',
              'promocode': true,
              'amount': promocode.params?.bonusProductsPcs?.toString() ?? '1',
            };

            Order.setOrder(productData['product_id'].toString(), orderData);
          }
        }
        promocodeStore.setPromocode(promocode);
        break;

      case 2: // Fixed discount
        final discount = ((promocode.params?.discountValue ?? 0) / 100).toDouble();

        promocodeStore.setPromocodePrice(discount);
        promocodeStore.setPromocode(promocode);
        setState(() {
          promotionPrice = discount;
        });
        // final discount = (promocode.params?.discountValue ?? 0).toDouble();
        // promocodeStore.setPromocodePrice(discount);
        // setState(() {
        //   promotionPrice = discount;
        // });
        break;

      case 3: // Percentage discount
        final discountPercent = promocode.params?.discountValue?.toDouble() ?? 0;

        // Check for special promocodes
        final promocodeName = promocode.name?.split('\$').last?.toLowerCase() ?? '';

        if (promocodeName == 'bday20') {
          final isValidBirthday = await checkBirthday();
          if (!isValidBirthday) {
            setState(() {
              errorMessage = 'Промокод действителен только в день рождения';
            });
            return;
          }
        }

        if (promocodeName == 'first20') {
          final isFirstOrder = await checkFirstOrder();
          if (!isFirstOrder) {
            setState(() {
              errorMessage = 'Промокод действителен только для первого заказа';
            });
            return;
          }
        }

        promocodeStore.setDiscountPromocode(discountPercent);
        promocodeStore.setPromocode(promocode);
        setState(() {
          promotionDiscount = discountPercent;
        });
        break;
    }
  }

  Future<bool> checkBirthday() async {
    try {
      if (!User.isKeyAvalible('birthday')) return false;

      final birthday = DateTime.tryParse(User.getUserInfo('birthday'));
      if (birthday == null) return false;

      final today = DateTime.now();
      return today.month == birthday.month && today.day == birthday.day;
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkFirstOrder() async {
    try {
      final clientInfo = await Api.getClient(
        User.getUserInfo('phone'),
        User.getUserInfo('password'),
      );

      if (clientInfo['res'] != true) return false;

      final comment = clientInfo['comment'];
      if (comment == null) return true;

      Map<String, dynamic> commentData;
      if (comment is String) {
        commentData = jsonDecode(comment);
      } else {
        commentData = comment;
      }

      final orderLength = int.tryParse(commentData['length']?.toString() ?? '0') ?? 0;
      return orderLength == 0;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hasActivePromo = promocodeStore.activePromocode.value != null;

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              hasActivePromo ? 'Активный промокод' : 'Введите промокод',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: cDarkGreen,
              ),
            ),
            const SizedBox(height: 20),

            if (hasActivePromo) ...[
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            promocodeStore.getPromocodeName(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: cDarkGreen,
                            ),
                          ),
                          Text(promocodeStore.getPromocodeDescription()),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: handleRemovePromo,
                      icon: const Icon(Icons.close, color: Colors.red),
                    ),
                  ],
                ),
              ),
            ] else ...[
              TextField(
                controller: promoCodeController,
                decoration: InputDecoration(
                  labelText: 'Промокод',
                  hintText: 'Введите промокод',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  errorText: errorMessage,
                  prefixIcon: const Icon(Icons.local_offer),
                ),
                onChanged: (value) {
                  setState(() {
                    errorMessage = null;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Show discount info if available
              if (promotionPrice > 0 || promotionDiscount > 0) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.celebration, color: Colors.green),
                      const SizedBox(width: 10),
                      Text(
                        promotionPrice > 0
                            ? 'Скидка ${promotionPrice.toStringAsFixed(0)} сум'
                            : 'Скидка ${promotionDiscount.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLoading ? null : handleApply,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cDarkGreen,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Text(
                        'Применить',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text(
                      'Отмена',
                      style: TextStyle(color: cDarkGreen),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }

  @override
  void dispose() {
    promoCodeController.dispose();
    super.dispose();
  }
}