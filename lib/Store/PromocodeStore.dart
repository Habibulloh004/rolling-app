import 'dart:convert';
import 'package:get/get.dart' hide Condition;
import 'package:hive/hive.dart';
import 'package:flutter_localization/flutter_localization.dart';
import '../Models/Promocode.dart';
import '../Models/Product.dart';
import '../LocalMemory/Order.dart';
import '../LocalMemory/User.dart';
import '../Consts/Functions.dart';
import '../Backend/Api.dart';
import '../Localzition/locals.dart';

class PromocodeStore extends GetxController {
  static PromocodeStore get to => Get.find();

  final Rxn<Promocode> activePromocode = Rxn<Promocode>();
  final RxDouble promocodePrice = 0.0.obs;
  final RxDouble discountPromocode = 0.0.obs;
  final RxDouble discountPromocodeProduct = 0.0.obs;
  final RxList<Product> bonusProducts = <Product>[].obs;
  final RxBool isProcessing = false.obs;

  late Box _promocodeBox;

  @override
  void onInit() {
    super.onInit();
    _initializeBox();
  }

  void _initializeBox() async {
    try {
      _promocodeBox = await Hive.openBox('promocode_state');
      Future.delayed(Duration.zero, () {
        _restorePromocodeState();
      });
    } catch (e) {
      print('Error initializing promocode box: $e');
    }
  }

  void _restorePromocodeState() {
    try {
      final savedPromocodeJson = _promocodeBox.get('active_promocode');
      if (savedPromocodeJson != null) {
        final promocodeData = jsonDecode(savedPromocodeJson);
        final promocode = Promocode.fromJson(promocodeData);

        activePromocode.value = promocode;
        promocodePrice.value = _promocodeBox.get('promocode_price') ?? 0.0;
        discountPromocode.value = _promocodeBox.get('discount_promocode') ?? 0.0;
        discountPromocodeProduct.value = _promocodeBox.get('discount_promocode_product') ?? 0.0;

        // Restore bonus products from order
        _restoreBonusProductsFromOrder();

        print('Restored promocode state: ${promocode.name}');
        validatePromocodeOnCartChange();
      }
    } catch (e) {
      print('Error restoring promocode state: $e');
      _clearSavedState();
    }
  }

  void _restoreBonusProductsFromOrder() {
    try {
      final orders = Order.getFullOrder();
      final bonusProductsInCart = orders.where((order) => order['promocode'] == true).toList();

      bonusProducts.clear();
      for (var order in bonusProductsInCart) {
        final product = Product(
          productId: order['productId'] ?? '',
          name: order['name'] ?? '',
          description: order['description'] ?? '',
          ingredients: order['ingredients'] ?? '',
          price: order['price'] ?? '0',
          weight: order['weight'] ?? '',
          photo: order['photo'] ?? '',
        );
        bonusProducts.add(product);
      }
    } catch (e) {
      print('Error restoring bonus products: $e');
    }
  }

  // Main public methods matching JSX functionality

  void handleRemovePromo() {
    if (isProcessing.value) return;

    isProcessing.value = true;

    try {
      print('Removing promocode and bonus products');

      // Clear promocode state
      activePromocode.value = null;
      promocodePrice.value = 0;
      discountPromocode.value = 0;
      discountPromocodeProduct.value = 0;
      bonusProducts.clear();

      // Remove bonus products from order
      _removeSpecificBonusProducts();

      // Clear saved state
      _clearSavedState();

      update();
      Get.forceAppUpdate();

    } catch (e) {
      print('Error removing promocode: $e');
    } finally {
      isProcessing.value = false;
    }
  }

  Future<bool> applyPromocode(
      String promoCode,
      List<dynamic> promotions,
      List<dynamic> productsData,
      List<dynamic> categoriesData,
      Function(String) onError,
      Function(String) onSuccess,
      ) async {
    if (isProcessing.value) return false;

    isProcessing.value = true;

    try {
      if (promoCode.isEmpty) {
        onError(_getLocalizedText('pleaseEnterPromocode'));
        return false;
      }

      if (activePromocode.value != null) {
        onError(_getLocalizedText('promocodeAlreadyUsed'));
        return false;
      }

      // Find promocode - fixed to avoid null return type error
      dynamic findPromo;
      try {
        findPromo = promotions.firstWhere(
              (promo) {
            if (promo == null) return false;
            final promoCodeFind = promo['name']?.toString().split('\$');
            if (promoCodeFind != null && promoCodeFind.length > 1) {
              return promoCodeFind[1].toLowerCase().trim() == promoCode.toLowerCase().trim();
            }
            return false;
          },
        );
      } catch (e) {
        findPromo = null;
      }

      if (findPromo == null) {
        onError(_getLocalizedText('invalidPromocode'));
        return false;
      }

      final promocode = Promocode.fromJson(findPromo);

      // Check auth requirement - matching JSX logic
      if (promocode.params?.clientsType == 3 && !User.isKeyAvalible('id')) {
        onError(_getLocalizedText('authRequiredForPromocode'));
        return false;
      }

      // Validate conditions
      final validationResult = await _validatePromocodeConditions(
          promocode, productsData, categoriesData, onError
      );

      if (!validationResult) {
        return false;
      }

      // Apply promocode based on result type
      final applyResult = await _applyPromocodeByType(
          promocode, productsData, onError, onSuccess
      );

      if (applyResult) {
        setPromocode(promocode);
        onSuccess(_getLocalizedText('promocodeApplied'));
      }

      return applyResult;

    } catch (e) {
      print('Error applying promocode: $e');
      onError(_getLocalizedText('errorApplyingPromocode'));
      return false;
    } finally {
      isProcessing.value = false;
    }
  }

  Future<bool> _validatePromocodeConditions(
      Promocode promocode,
      List<dynamic> productsData,
      List<dynamic> categoriesData,
      Function(String) onError,
      ) async {
    final conditions = promocode.params?.conditions ?? [];
    final orders = Order.getFullOrder();
    final regularOrders = orders.where((order) => order['promocode'] != true).toList();
    final totalSum = _calculateRegularOrderTotal(regularOrders);

    for (final condition in conditions) {
      switch (condition.type) {
        case 0: // All products - matching JSX logic
          final requiredSum = (condition.sum ?? 0) ~/ 100;
          if (totalSum < requiredSum) {
            onError('${makePriceSomString(requiredSum)} ${_getLocalizedText('som')} ${_getLocalizedText('minimumOrderAmount')}');
            return false;
          }
          break;

        case 1: // Category - matching JSX logic
          final findCategoryData = regularOrders.where((order) {
            final productIndex = productsData.indexWhere(
                    (p) => p['product_id'].toString() == order['productId']
            );
            if (productIndex == -1) return false;
            final product = productsData[productIndex];
            return product['menu_category_id'].toString() == condition.id;
          }).toList();

          if (findCategoryData.isEmpty) {
            final categoryIndex = categoriesData.indexWhere(
                    (c) => c['category_id'].toString() == condition.id
            );
            final categoryName = categoryIndex != -1
                ? splitText(categoriesData[categoryIndex]['category_name'])
                : _getLocalizedText('category');
            onError('${makePriceSomString((condition.sum ?? 0) ~/ 100)} ${_getLocalizedText('som')} ${_getLocalizedText('minimumOrderAmount')} - $categoryName');
            return false;
          }

          final categorySum = findCategoryData.fold<int>(0, (sum, order) {
            final price = int.tryParse(order['price']?.toString().replaceAll(' ', '') ?? '0') ?? 0;
            final amount = int.tryParse(order['amount']?.toString() ?? '1') ?? 1;
            return sum + (price * amount);
          });

          if (categorySum < (condition.sum ?? 0) ~/ 100) {
            final categoryIndex = categoriesData.indexWhere(
                    (c) => c['category_id'].toString() == condition.id
            );
            final categoryName = categoryIndex != -1
                ? splitText(categoriesData[categoryIndex]['category_name'])
                : _getLocalizedText('category');
            onError('${makePriceSomString((condition.sum ?? 0) ~/ 100)} ${_getLocalizedText('som')} ${_getLocalizedText('minimumOrderAmount')} - $categoryName');
            return false;
          }
          break;

        case 2: // Specific product - matching JSX logic
          final findProductsData = regularOrders.where((order) =>
          order['productId'].toString() == condition.id
          ).toList();

          if (findProductsData.isEmpty) {
            final productIndex = productsData.indexWhere(
                    (p) => p['product_id'].toString() == condition.id
            );
            final productName = productIndex != -1
                ? productsData[productIndex]['product_name']
                : _getLocalizedText('products');
            onError('${makePriceSomString((condition.sum ?? 0) ~/ 100)} ${_getLocalizedText('som')} ${_getLocalizedText('minimumOrderAmount')} - $productName');
            return false;
          }

          final productSum = findProductsData.fold<int>(0, (sum, order) {
            final price = int.tryParse(order['price']?.toString().replaceAll(' ', '') ?? '0') ?? 0;
            final amount = int.tryParse(order['amount']?.toString() ?? '1') ?? 1;
            return sum + (price * amount);
          });

          if (productSum < (condition.sum ?? 0) ~/ 100) {
            final productIndex = productsData.indexWhere(
                    (p) => p['product_id'].toString() == condition.id
            );
            final productName = productIndex != -1
                ? productsData[productIndex]['product_name']
                : _getLocalizedText('products');
            onError('${makePriceSomString((condition.sum ?? 0) ~/ 100)} ${_getLocalizedText('som')} ${_getLocalizedText('minimumOrderAmount')} - $productName');
            return false;
          }
          break;
      }
    }
    return true;
  }

  // Fix for lib/Store/PromocodeStore.dart

  Future<bool> _applyPromocodeByType(
      Promocode promocode,
      List<dynamic> productsData,
      Function(String) onError,
      Function(String) onSuccess,
      ) async {
    switch (promocode.params?.resultType) {
      case 1: // Bonus products - fixed to avoid null return type error
        final filterProducts = productsData.where((product) {
          final bonusProducts = promocode.params?.bonusProducts ?? [];
          return bonusProducts.any((pr) => pr.id == product['product_id'].toString());
        }).toList();

        final bonusProductsList = <Product>[];
        for (final prd in filterProducts) {
          // ✅ Fixed: Store description for translation
          final rawDescription = prd['product_production_description']?.toString() ?? '';
          
          final product = Product(
            productId: prd['product_id'].toString(),
            name: splitText(rawDescription.isNotEmpty ? rawDescription : prd['product_name'] ?? ''), // Use splitText
            description: rawDescription, // Store raw description for translation
            ingredients: '',
            price: '0',
            weight: prd['out']?.toString() ?? '',
            photo: prd['photo_origin'] != null
                ? "https://rolling-sushi.joinposter.com${prd['photo_origin']}"
                : '',
          );
          bonusProductsList.add(product);

          // Add to order with promocode flag
          final orderData = {
            'productId': product.productId,
            'name': product.name, // Already translated name
            'description': product.description, // Raw description for future translation
            'ingredients': product.ingredients,
            'price': product.price,
            'weight': product.weight,
            'photo': product.photo,
            'promocode': true,
            'amount': promocode.params?.bonusProductsPcs?.toString() ?? '1',
          };
          Order.setOrder(product.productId, orderData);
        }

        addBonusProducts(bonusProductsList);
        break;

      case 2: // Sum discount - matching JSX logic
        final discountValue = (promocode.params?.discountValue ?? 0) / 100.0;
        setPromocodePrice(discountValue);
        break;

      case 3: // Percentage discount - matching JSX logic
        final promocodeName = promocode.name?.split('\$').last?.toLowerCase() ?? '';

        // Birthday check - matching JSX logic
        if (promocodeName == 'bday20') {
          final isValidBirthday = await _checkBirthday();
          if (!isValidBirthday) {
            onError(_getLocalizedText('promocodeValidOnlyOnBirthday'));
            return false;
          }
        }

        // First order check - matching JSX logic  
        if (promocodeName == 'first20') {
          final isFirstOrder = await _checkFirstOrder();
          if (!isFirstOrder) {
            onError(_getLocalizedText('promocodeValidOnlyForFirstOrder'));
            return false;
          }
        }

        final discountValue = promocode.params?.discountValue?.toDouble() ?? 0;

        // Determine which discount type to apply based on conditions
        final conditions = promocode.params?.conditions ?? [];
        bool hasSpecificCondition = false;
        
        // Check if there are specific product or category conditions
        for (final condition in conditions) {
          if (condition.type == 2 || condition.type == 1) { // Product or category specific
            hasSpecificCondition = true;
            break;
          }
        }

        if (hasSpecificCondition) {
          setDiscountPromocodeProduct(discountValue);
        } else {
          // For general conditions (type 0) or no specific conditions
          setDiscountPromocode(discountValue);
        }
        break;
    }
    return true;
  }

  Future<bool> _checkBirthday() async {
    try {
      // Get fresh data from server to ensure accuracy
      if (!User.isKeyAvalible('phone') || !User.isKeyAvalible('password')) {
        return false; // No user data, can't validate birthday
      }

      final clientInfo = await Api.getClient(
        User.getUserInfo('phone'),
        User.getUserInfo('password'),
      );

      if (clientInfo['res'] != true) return false;

      final birthdayStr = clientInfo['birthday'];
      if (birthdayStr == null || birthdayStr.isEmpty) return false;

      final birthday = DateTime.tryParse(birthdayStr);
      if (birthday == null) return false;

      final today = DateTime.now();
      
      // Match JSX logic exactly: compare month and day
      return today.month == birthday.month && today.day == birthday.day;
    } catch (e) {
      print('Error checking birthday: $e');
      return false; // Default to not allowing birthday promocode on error
    }
  }

  Future<bool> _checkFirstOrder() async {
    try {
      // Get fresh data from server like PromocodeDialog does
      if (!User.isKeyAvalible('phone') || !User.isKeyAvalible('password')) {
        return true; // If no user data, consider as first order
      }

      final clientInfo = await Api.getClient(
        User.getUserInfo('phone'),
        User.getUserInfo('password'),
      );

      if (clientInfo['res'] != true) return true;

      final comment = clientInfo['comment'];
      
      // Match JSX logic: if comment is null, it's first order
      if (comment == null) return true;

      Map<String, dynamic> commentData;
      try {
        if (comment is String) {
          commentData = jsonDecode(comment);
        } else {
          commentData = comment;
        }
      } catch (e) {
        // If can't parse comment, consider as first order
        return true;
      }

      // Match JSX logic: check for both null/missing length AND zero length
      final lengthValue = commentData['length'];
      if (lengthValue == null) return true; // No length property = first order
      
      final orderLength = int.tryParse(lengthValue.toString()) ?? 0;
      return orderLength == 0; // Zero length = first order
    } catch (e) {
      print('Error checking first order: $e');
      return true; // Default to allowing first order promocode on error
    }
  }

  void validatePromocodeOnCartChange() {
    if (activePromocode.value != null && !isProcessing.value) {
      print('Validating promocode on cart change');
      _validateCurrentPromocode();
    }
  }

  void _validateCurrentPromocode() {
    if (activePromocode.value == null || isProcessing.value) return;

    try {
      final promocode = activePromocode.value!;
      final conditions = promocode.params?.conditions ?? [];
      final orders = Order.getFullOrder();
      final regularOrders = orders.where((order) => order['promocode'] != true).toList();
      final totalSum = _calculateRegularOrderTotal(regularOrders);

      for (final condition in conditions) {
        switch (condition.type) {
          case 0: // All products
            final requiredSum = (condition.sum ?? 0) ~/ 100;
            if (totalSum < requiredSum) {
              print('Total sum $totalSum is less than required $requiredSum');
              handleRemovePromo();
              return;
            }
            break;

          case 2: // Specific product
            final findProductsData = regularOrders.where((order) =>
            order['productId'].toString() == condition.id
            ).toList();

            if (findProductsData.isEmpty) {
              print('Required product ${condition.id} not found in cart');
              handleRemovePromo();
              return;
            }

            final productSum = findProductsData.fold<int>(0, (sum, order) {
              final price = int.tryParse(order['price']?.toString().replaceAll(' ', '') ?? '0') ?? 0;
              final amount = int.tryParse(order['amount']?.toString() ?? '1') ?? 1;
              return sum + (price * amount);
            });

            if (productSum < (condition.sum ?? 0) ~/ 100) {
              print('Product sum $productSum is less than required ${(condition.sum ?? 0) ~/ 100}');
              handleRemovePromo();
              return;
            }
            break;
        }
      }

      // Check if bonus products are still in cart for bonus type promocodes
      if (promocode.params?.resultType == 1) {
        final bonusProductsInCart = orders.where((order) => order['promocode'] == true).toList();
        if (bonusProductsInCart.isEmpty) {
          print('Bonus products missing from cart, removing promocode');
          handleRemovePromo();
          return;
        }
      }

      print('Promocode conditions still met');
    } catch (e) {
      print('Error validating promocode: $e');
      handleRemovePromo();
    }
  }

  int _calculateRegularOrderTotal(List<Map> regularOrders) {
    int total = 0;
    for (var order in regularOrders) {
      try {
        final priceString = order['price']?.toString().replaceAll(' ', '') ?? '0';
        final price = int.tryParse(priceString) ?? 0;
        final amount = int.tryParse(order['amount']?.toString() ?? '1') ?? 1;
        total += price * amount;
      } catch (e) {
        print('Error calculating order total: $e');
      }
    }
    return total;
  }

  void _removeSpecificBonusProducts() {
    try {
      final orders = Order.getFullOrder();
      List<int> bonusIndices = [];

      for (int i = 0; i < orders.length; i++) {
        if (orders[i]['promocode'] == true) {
          bonusIndices.add(i);
        }
      }

      // Remove from highest index to lowest to avoid index shifting
      bonusIndices.sort((a, b) => b.compareTo(a));
      for (int index in bonusIndices) {
        Order.deleteOrderAt(index);
      }

      print('Removed ${bonusIndices.length} bonus products');
    } catch (e) {
      print('Error removing bonus products: $e');
    }
  }

  // Setters and state management

  void setPromocode(Promocode? promo) {
    activePromocode.value = promo;
    _savePromocodeState();
  }

  void setPromocodePrice(double price) {
    promocodePrice.value = price;
    _savePromocodeState();
  }

  void setDiscountPromocode(double discount) {
    discountPromocode.value = discount;
    _savePromocodeState();
  }

  void setDiscountPromocodeProduct(double discount) {
    discountPromocodeProduct.value = discount;
    _savePromocodeState();
  }

  void addBonusProducts(List<Product> products) {
    bonusProducts.clear();
    bonusProducts.addAll(products);
    _savePromocodeState();
  }

  void _savePromocodeState() {
    try {
      if (_promocodeBox.isOpen) {
        if (activePromocode.value != null) {
          _promocodeBox.put('active_promocode', jsonEncode(activePromocode.value!.toJson()));
        } else {
          _promocodeBox.delete('active_promocode');
        }
        _promocodeBox.put('promocode_price', promocodePrice.value);
        _promocodeBox.put('discount_promocode', discountPromocode.value);
        _promocodeBox.put('discount_promocode_product', discountPromocodeProduct.value);
      }
    } catch (e) {
      print('Error saving promocode state: $e');
    }
  }

  void _clearSavedState() {
    try {
      if (_promocodeBox.isOpen) {
        _promocodeBox.clear();
      }
    } catch (e) {
      print('Error clearing promocode state: $e');
    }
  }

  // Utility methods

  double getTotalDiscount() {
    if (discountPromocode.value > 0) {
      return discountPromocode.value;
    } else if (discountPromocodeProduct.value > 0) {
      return discountPromocodeProduct.value;
    }
    return 0;
  }

  double getTotalPrice(double orderPrice) {
    // Absolute discount (sum off total)
    if (promocodePrice.value > 0) {
      return (orderPrice - promocodePrice.value).clamp(0, double.infinity);
    }

    // Product/category-only percentage discount
    if (discountPromocodeProduct.value > 0 && activePromocode.value != null) {
      try {
        final orders = Order.getFullOrder();
        final conditions = activePromocode.value!.params?.conditions ?? [];
        // Sum eligible items according to conditions (product or category)
        int eligibleSum = 0;

        for (final condition in conditions) {
          if (condition.type == 2) {
            // Specific product id
            final productId = condition.id?.toString();
            final subset = orders.where((o) =>
              o['promocode'] != true && o['productId']?.toString() == productId);
            for (final o in subset) {
              final price = int.tryParse(o['price']?.toString().replaceAll(' ', '') ?? '0') ?? 0;
              final amount = int.tryParse(o['amount']?.toString() ?? '1') ?? 1;
              eligibleSum += price * amount;
            }
          } else if (condition.type == 1) {
            // Category id: need productsData to map; fallback to apply on total if unknown
            // Without products catalog here, approximate by applying on full total
            // to avoid under-discounting; refine if productsData mapping available
            eligibleSum = orderPrice.toInt();
          }
        }

        final discount = eligibleSum * (discountPromocodeProduct.value / 100.0);
        return (orderPrice - discount).clamp(0, double.infinity);
      } catch (_) {
        // Fallback to total percent if something goes wrong
        return orderPrice * (1 - discountPromocodeProduct.value / 100.0);
      }
    }

    // Whole-cart percentage discount
    if (discountPromocode.value > 0) {
      return orderPrice * (1 - discountPromocode.value / 100);
    }

    return orderPrice;
  }

  bool hasActivePromocode() {
    return activePromocode.value != null;
  }

  String getPromocodeDescription() {
    if (!hasActivePromocode()) return '';

    final promo = activePromocode.value!;
    final params = promo.params;
    if (params == null) return '';

    switch (params.resultType) {
      case 1:
        return _getLocalizedText('bonusProducts');
      case 2:
        return '${_getLocalizedText('discount')} ${promocodePrice.value.toStringAsFixed(0)} ${_getLocalizedText('som')}';
      case 3:
        final shown = discountPromocode.value > 0
            ? discountPromocode.value
            : (params.discountValue?.toDouble() ?? 0);
        return '${_getLocalizedText('discount')} ${shown.toStringAsFixed(0)}%';
      default:
        return '';
    }
  }

  String getPromocodeName() {
    final name = activePromocode.value?.name ?? '';
    if (name.contains('\$')) {
      final parts = name.split('\$');
      return parts.length > 1 ? parts[1] : name;
    }
    return name;
  }

  // Helper method to get localized text
  String _getLocalizedText(String key) {
    try {
      // Use the current context to get localized strings
      // This is a simplified approach - you might need to adjust based on your localization setup
      switch (key) {
        case 'pleaseEnterPromocode':
          return 'Please enter promocode'; // Default fallback
        case 'promocodeAlreadyUsed':
          return 'Promocode already in use';
        case 'invalidPromocode':
          return 'Invalid promocode';
        case 'authRequiredForPromocode':
          return 'Authentication required to use this promocode';
        case 'minimumOrderAmount':
          return 'Minimum order amount';
        case 'promocodeValidOnlyOnBirthday':
          return 'Promocode valid only on birthday';
        case 'promocodeValidOnlyForFirstOrder':
          return 'Promocode valid only for first order';
        case 'errorApplyingPromocode':
          return 'Error applying promocode';
        case 'promocodeApplied':
          return 'Promocode applied';
        case 'bonusProducts':
          return 'Bonus Products';
        case 'discount':
          return 'Discount';
        case 'som':
          return 'som';
        case 'category':
          return 'category';
        case 'products':
          return 'product';
        default:
          return key;
      }
    } catch (e) {
      // Fallback to key if localization fails
      return key;
    }
  }

  @override
  void onClose() {
    try {
      if (_promocodeBox.isOpen) {
        _promocodeBox.close();
      }
    } catch (e) {
      print('Error closing promocode box: $e');
    }
    super.onClose();
  }
}