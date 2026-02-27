import 'dart:convert';

import 'package:flutter_localization/flutter_localization.dart';
import 'package:get/get.dart' hide Condition;
import 'package:hive/hive.dart';

import '../Backend/Api.dart';
import '../Consts/Functions.dart';
import '../LocalMemory/Language.dart';
import '../LocalMemory/Order.dart';
import '../LocalMemory/User.dart';
import '../Localzition/locals.dart';
import '../Models/Product.dart';
import '../Models/Promocode.dart';

class PromocodeStore extends GetxController {
  static PromocodeStore get to => Get.find();

  final Rxn<Promocode> activePromocode = Rxn<Promocode>();
  final RxDouble promocodePrice = 0.0.obs;
  final RxDouble discountPromocode = 0.0.obs;
  final RxDouble discountPromocodeProduct = 0.0.obs;
  final RxList<Product> bonusProducts = <Product>[].obs;
  final RxBool isProcessing = false.obs;

  List<dynamic>? _cachedProductsData;
  List<dynamic>? _cachedCategoriesData;
  final Map<String, String> _productCategoryMap = {};
  final Map<String, Set<String>> _categoryChildrenMap = {};
  final Map<String, String> _categoryParentMap = {};
  final Map<String, Set<String>> _categoryDescendantsCache = {};
  final Map<String, String> _categoryNameMap = {};
  final Set<String> _detectedSetCategoryIds = <String>{};
  final Map<String, bool> _setMembershipCache = {};

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
        discountPromocode.value =
            _promocodeBox.get('discount_promocode') ?? 0.0;
        discountPromocodeProduct.value =
            _promocodeBox.get('discount_promocode_product') ?? 0.0;

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
      final bonusProductsInCart =
          orders.where((order) => order['promocode'] == true).toList();

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

  void cacheBackendData({
    List<dynamic>? productsData,
    List<dynamic>? categoriesData,
  }) {
    if (productsData != null) {
      _cachedProductsData = List<dynamic>.from(productsData);
      _productCategoryMap
        ..clear()
        ..addEntries(productsData.whereType<Map>().map((product) {
          final productId = product['product_id']?.toString();
          final categoryId = product['menu_category_id']?.toString();
          return MapEntry(
            productId ?? '',
            categoryId ?? '',
          );
        }).where((entry) => entry.key.isNotEmpty && entry.value.isNotEmpty));
      _setMembershipCache.clear();
    }

    if (categoriesData != null) {
      _cachedCategoriesData = List<dynamic>.from(categoriesData);
      _buildCategoryHierarchy(_cachedCategoriesData!);
      _identifySetCategories(_cachedCategoriesData!);
      _setMembershipCache.clear();
    }
  }

  void _buildCategoryHierarchy(List<dynamic> categories) {
    _categoryChildrenMap.clear();
    _categoryParentMap.clear();
    _categoryDescendantsCache.clear();
    _categoryNameMap.clear();

    for (final raw in categories) {
      if (raw is! Map) continue;
      final id = _resolveCategoryId(raw);
      if (id == null) continue;
      final name = _extractCategoryName(raw);
      if (name != null && name.isNotEmpty) {
        _categoryNameMap[id] = name;
      }
      _categoryChildrenMap.putIfAbsent(id, () => <String>{});
      _categoryParentMap.putIfAbsent(id, () => '');
    }

    for (final raw in categories) {
      if (raw is! Map) continue;
      final id = _resolveCategoryId(raw);
      if (id == null) continue;

      final parentId = _resolveParentCategoryId(raw);
      if (parentId == null || parentId.isEmpty || parentId == id) continue;

      if (_shouldSkipCategoryInheritance(parentId, id)) {
        continue;
      }

      final children =
          _categoryChildrenMap.putIfAbsent(parentId, () => <String>{});
      children.add(id);
      _categoryParentMap[id] = parentId;
    }

    for (final raw in categories) {
      if (raw is! Map) continue;
      final parentId = _resolveCategoryId(raw);
      if (parentId == null) continue;

      final nested = raw['nested_categories'];
      if (nested is! List) continue;

      final children =
          _categoryChildrenMap.putIfAbsent(parentId, () => <String>{});
      for (final child in nested) {
        final childId = _normalizeId(child);
        if (childId != null && childId != parentId) {
          if (_shouldSkipCategoryInheritance(parentId, childId)) {
            continue;
          }
          children.add(childId);
          final currentParent = _categoryParentMap[childId];
          if (currentParent == null || currentParent.isEmpty) {
            _categoryParentMap[childId] = parentId;
          }
          _categoryChildrenMap.putIfAbsent(childId, () => <String>{});
        }
      }
    }
  }

  void _identifySetCategories(List<dynamic> categories) {
    _detectedSetCategoryIds.clear();
    if (categories.isEmpty) return;

    for (final raw in categories) {
      if (raw is! Map) continue;
      final id = _resolveCategoryId(raw);
      if (id == null || id.isEmpty) continue;

      if (!_isLikelySetCategory(raw)) continue;

      final descendants = _getAllDescendantCategoryIds(id);
      if (descendants.isEmpty) {
        _detectedSetCategoryIds.add(id);
      } else {
        _detectedSetCategoryIds.addAll(descendants);
      }
    }
  }

  bool _isLikelySetCategory(Map<dynamic, dynamic> category) {
    final candidates = <String>[
      category['category_name']?.toString() ?? '',
      category['name']?.toString() ?? '',
      category['title']?.toString() ?? '',
      category['label']?.toString() ?? '',
      category['category_tag']?.toString() ?? '',
    ];

    for (final raw in candidates) {
      if (raw.isEmpty) continue;
      final normalized = raw.toLowerCase();
      if (_matchesSetKeyword(normalized)) {
        return true;
      }
    }

    return false;
  }

  bool _matchesSetKeyword(String value) {
    const keywords = ['сет', 'set'];
    for (final keyword in keywords) {
      if (value.contains(keyword)) {
        return true;
      }
    }
    return false;
  }

  String? _extractCategoryName(Map<dynamic, dynamic> category) {
    final candidates = <String>[
      category['category_name']?.toString() ?? '',
      category['name']?.toString() ?? '',
      category['title']?.toString() ?? '',
      category['label']?.toString() ?? '',
      category['category_tag']?.toString() ?? '',
    ];

    for (final candidate in candidates) {
      if (candidate.isNotEmpty) {
        return candidate;
      }
    }

    return null;
  }

  bool _shouldSkipCategoryInheritance(String? parentId, String? childId) {
    if (parentId == null ||
        parentId.isEmpty ||
        childId == null ||
        childId.isEmpty) {
      return false;
    }

    final parentName = _categoryNameMap[parentId];
    final childName = _categoryNameMap[childId];

    if (parentName == null || childName == null) {
      return false;
    }

    final parentLower = parentName.toLowerCase();
    final childLower = childName.toLowerCase();
    final childCollapsed = childLower.replaceAll(RegExp(r'[\s_\-]+'), '');

    final parentLooksLikeSets =
        parentLower.contains('set') || parentLower.contains('сет');
    final childLooksLikeMiniSets =
        childLower.contains('mini set') ||
        childLower.contains('mini-set') ||
        childCollapsed.contains('miniset') ||
        childLower.contains('мини сет') ||
        childLower.contains('мини-сет') ||
        childCollapsed.contains('минисет');

    if (!parentLooksLikeSets || !childLooksLikeMiniSets) {
      return false;
    }

    return true;
  }

  String? _resolveCategoryId(Map<dynamic, dynamic> category) {
    const possibleKeys = [
      'category_id',
      'menu_category_id',
      'id',
    ];
    for (final key in possibleKeys) {
      if (!category.containsKey(key)) continue;
      final id = _normalizeId(category[key]);
      if (id != null) return id;
    }
    return null;
  }

  String? _resolveParentCategoryId(Map<dynamic, dynamic> category) {
    const possibleKeys = [
      'parent_category_id',
      'category_parent_id',
      'parent_category',
      'menu_category_parent_id',
      'parent_id',
      'category_parent',
    ];

    for (final key in possibleKeys) {
      if (!category.containsKey(key)) continue;
      final parentId = _normalizeId(category[key]);
      if (parentId != null) return parentId;
    }

    final parent = category['parent'];
    if (parent is Map) {
      final nestedParentId = _resolveCategoryId(parent);
      if (nestedParentId != null) return nestedParentId;
    }
    return null;
  }

  String? _normalizeId(dynamic value) {
    if (value == null) return null;

    if (value is Map) {
      final nested = _normalizeId(value['id'] ?? value['category_id']);
      if (nested != null) return nested;
    }

    final stringValue = value.toString().trim();
    if (stringValue.isEmpty ||
        stringValue == '0' ||
        stringValue.toLowerCase() == 'null') {
      return null;
    }
    return stringValue;
  }

  Set<String> _getAllDescendantCategoryIds(String categoryId) {
    if (categoryId.isEmpty) return <String>{};
    final cached = _categoryDescendantsCache[categoryId];
    if (cached != null) return cached;

    final descendants = _collectDescendants(categoryId, <String>{});
    _categoryDescendantsCache[categoryId] = descendants;
    return descendants;
  }

  Set<String> _collectDescendants(String categoryId, Set<String> visited) {
    if (categoryId.isEmpty || visited.contains(categoryId)) {
      return <String>{};
    }

    final nextVisited = Set<String>.from(visited)..add(categoryId);
    final result = <String>{categoryId};

    final children = _categoryChildrenMap[categoryId];
    if (children != null) {
      for (final child in children) {
        if (child.isEmpty) continue;
        result.addAll(_collectDescendants(child, nextVisited));
      }
    }

    return result;
  }

  String? _lookupProductCategoryId(
    String productId, {
    List<dynamic>? productsData,
  }) {
    if (productId.isEmpty) return null;

    final cached = _productCategoryMap[productId];
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    final source = productsData ?? _cachedProductsData;
    if (source != null) {
      for (final product in source) {
        if (product is! Map) continue;
        final id = _normalizeId(product['product_id']);
        if (id == productId) {
          final categoryId = _normalizeId(product['menu_category_id']);
          if (categoryId != null) {
            _productCategoryMap[productId] = categoryId;
            return categoryId;
          }
        }
      }
    }

    return null;
  }

  int _calculateOrderLineTotal(Map<dynamic, dynamic> order) {
    final priceRaw = order['price']?.toString().replaceAll(' ', '') ?? '0';
    final amountRaw = order['amount']?.toString() ?? '1';

    final price = int.tryParse(priceRaw) ?? 0;
    final amount = int.tryParse(amountRaw) ?? 1;

    return price * amount;
  }

  bool _isProductInCategoryTree(
    String productId,
    String categoryId, {
    List<dynamic>? productsData,
  }) {
    if (productId.isEmpty || categoryId.isEmpty) {
      return false;
    }

    final targetCategoryId = _normalizeId(categoryId);
    if (targetCategoryId == null || targetCategoryId.isEmpty) {
      return false;
    }

    final productCategoryId =
        _lookupProductCategoryId(productId, productsData: productsData);
    if (productCategoryId == null || productCategoryId.isEmpty) {
      return false;
    }

    var currentCategoryId = productCategoryId;
    final visited = <String>{};

    while (currentCategoryId.isNotEmpty && visited.add(currentCategoryId)) {
      if (currentCategoryId == targetCategoryId) {
        return true;
      }

      final parentId = _categoryParentMap[currentCategoryId];
      if (parentId == null || parentId.isEmpty) {
        break;
      }
      currentCategoryId = parentId;
    }

    if (_categoryParentMap.isEmpty) {
      final candidateCategories =
          _getAllDescendantCategoryIds(targetCategoryId);
      if (candidateCategories.isEmpty) {
        return productCategoryId == targetCategoryId;
      }
      return candidateCategories.contains(productCategoryId);
    }

    return false;
  }

  Set<String> getCategoryTree(String categoryId) {
    if (categoryId.isEmpty) {
      return <String>{};
    }
    return Set<String>.from(_getAllDescendantCategoryIds(categoryId));
  }

  bool productMatchesCategoryTree(
    String productId,
    String categoryId, {
    List<dynamic>? productsData,
  }) {
    return _isProductInCategoryTree(
      productId,
      categoryId,
      productsData: productsData,
    );
  }

  bool _shouldLimitDiscountToSets(Promocode? promocode) {
    final params = promocode?.params;
    if (params == null) return false;
    return params.isSetOnly;
  }

  Set<String> _resolveSetCategoryIdsForPromo(Promocode? promocode) {
    final result = <String>{};
    if (promocode?.params != null) {
      final params = promocode!.params!;

      final configuredSetIds = params.setCategoryIds ?? const <String>[];
      for (final rawId in configuredSetIds) {
        final normalized = _normalizeId(rawId);
        if (normalized == null || normalized.isEmpty) continue;
        result.addAll(_getAllDescendantCategoryIds(normalized));
      }

      final conditions = params.conditions ?? [];
      for (final condition in conditions) {
        if (condition.type != 1) continue;
        final normalized = _normalizeId(condition.id);
        if (normalized == null || normalized.isEmpty) continue;
        result.addAll(_getAllDescendantCategoryIds(normalized));
      }
    }

    if (result.isEmpty) {
      result.addAll(_detectedSetCategoryIds);
    }

    return result;
  }

  bool _isProductSetItem(
    String productId, {
    Set<String>? explicitCategoryIds,
    List<dynamic>? productsData,
  }) {
    if (productId.isEmpty) return false;

    final categories = explicitCategoryIds ??
        (_detectedSetCategoryIds.isNotEmpty ? _detectedSetCategoryIds : null);

    if (categories == null || categories.isEmpty) {
      return false;
    }

    if (explicitCategoryIds == null) {
      final cached = _setMembershipCache[productId];
      if (cached != null) return cached;
    }

    final sourceProducts = productsData ?? _cachedProductsData;
    bool matches = false;
    for (final categoryId in categories) {
      if (categoryId.isEmpty) continue;
      if (_isProductInCategoryTree(
        productId,
        categoryId,
        productsData: sourceProducts,
      )) {
        matches = true;
        break;
      }
    }

    if (explicitCategoryIds == null) {
      _setMembershipCache[productId] = matches;
    }

    return matches;
  }

  int _calculateSetItemsSum(
    List<Map<dynamic, dynamic>> orders, {
    Set<String>? explicitCategoryIds,
    List<dynamic>? productsData,
  }) {
    int total = 0;
    for (final order in orders) {
      if (order['promocode'] == true) continue;

      final productId = order['productId']?.toString() ?? '';
      if (productId.isEmpty) continue;

      final isSetItem = _isProductSetItem(
        productId,
        explicitCategoryIds: explicitCategoryIds,
        productsData: productsData,
      );

      if (!isSetItem) continue;
      total += _calculateOrderLineTotal(order);
    }
    return total;
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
      cacheBackendData(
        productsData: productsData,
        categoriesData: categoriesData,
      );

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
              return promoCodeFind[1].toLowerCase().trim() ==
                  promoCode.toLowerCase().trim();
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

      final clientsType = promocode.params?.clientsType ?? 1;
      final requiredGroups = promocode.params?.clientsGroups ?? const <String>[];

      switch (clientsType) {
        case 2:
          if (User.isKeyAvalible('id')) {
            onError(_getLocalizedText('promocodeGuestsOnly'));
            return false;
          }
          break;
        case 3:
          if (!User.isKeyAvalible('id')) {
            onError(_getLocalizedText('authRequiredForPromocode'));
            return false;
          }
          break;
        case 4:
          if (!User.isKeyAvalible('id')) {
            onError(_getLocalizedText('authRequiredForPromocode'));
            return false;
          }
          final isEligible =
              await _isClientInRequiredGroups(requiredGroups);
          if (!isEligible) {
            onError(_getLocalizedText('promocodeGroupRestricted'));
            return false;
          }
          break;
        default:
          break;
      }

      if (!_isPromocodeActiveNow(promocode)) {
        onError(_getLocalizedText('promocodeNotAvailableNow'));
        return false;
      }

      // Validate conditions
      final validationResult = await _validatePromocodeConditions(
          promocode, productsData, categoriesData, onError);

      if (!validationResult) {
        return false;
      }

      // Apply promocode based on result type
      final applyResult = await _applyPromocodeByType(
          promocode, productsData, onError, onSuccess);

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
    final rawConditions = promocode.params?.conditions ?? [];
    final conditions =
        rawConditions.where((condition) => condition.active != false).toList();
    final orders = Order.getFullOrder();
    final regularOrders =
        orders.where((order) => order['promocode'] != true).toList();

    if (conditions.isEmpty) {
      return true;
    }

    final normalizedOrders = regularOrders
        .whereType<Map>()
        .map((entry) => entry.cast<dynamic, dynamic>())
        .toList();

    final evaluation = _evaluateConditions(
      promocode,
      normalizedOrders,
      productsData: productsData,
      categoriesData: categoriesData,
    );

    final rule = (promocode.params?.conditionsRule ?? 'and').toLowerCase();
    final requiredMatches = promocode.params?.conditionsExactly ?? 0;
    final meetsRule =
        _evaluateConditionsRule(evaluation.results, rule, requiredMatches);

    if (!meetsRule) {
      onError(evaluation.firstFailureMessage ??
          _getLocalizedText('invalidPromocode'));
      return false;
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
    _resetPromocodeDiscounts();
    _removeSpecificBonusProducts();
    bonusProducts.clear();
    _savePromocodeState();

    final resultType = promocode.params?.resultType;

    switch (resultType) {
      case 1:
        final bonusEntries = promocode.params?.bonusProducts ?? [];
        if (bonusEntries.isEmpty) {
          onError(_getLocalizedText('bonusProductsUnavailable'));
          return false;
        }

        final conditionType = promocode.params?.bonusProductsConditionType;
        final conditionValue = promocode.params?.bonusProductsConditionValue;
        final defaultBonusCount = promocode.params?.bonusProductsPcs ?? 1;

        final bonusList = <Product>[];
        var index = 0;

        for (final entry in bonusEntries) {
          final productId = entry.id ?? entry.productId ?? '';
          if (productId.isEmpty) {
            continue;
          }

          final productData = _findProductData(
            productId,
            productsData: productsData,
          );
          if (productData == null) {
            continue;
          }

          final basePrice =
              _getPosterPriceAppUnits(productId, productsData: productsData) ??
                  0;
          final unitPrice = _calculateBonusUnitPrice(
            basePrice: basePrice,
            conditionType: conditionType,
            conditionValue: conditionValue,
          );
          final priceString = makePriceSomString(unitPrice);

          final rawDescription =
              productData['product_production_description']?.toString() ?? '';
          final rawProductName = productData['product_name']?.toString() ?? '';
          final localizedName = rawProductName.isNotEmpty
              ? splitText(rawProductName)
              : splitText(rawDescription);

          final product = Product(
            productId: productId,
            name: localizedName,
            description: rawDescription,
            ingredients: '',
            price: priceString,
            weight: productData['out']?.toString() ?? '',
            photo: productData['photo_origin'] != null
                ? "https://rolling-sushi.joinposter.com${productData['photo_origin']}"
                : '',
          );
          bonusList.add(product);

          final orderKey = 'bonus_${product.productId}_$index';
          final bonusCount = entry.count ?? defaultBonusCount;

          final orderData = {
            'productId': product.productId,
            'name': localizedName,
            'description': product.description,
            'ingredients': product.ingredients,
            'price': priceString,
            'weight': product.weight,
            'photo': product.photo,
            'promocode': true,
            'amount': bonusCount.toString(),
          };

          Order.setOrder(orderKey, orderData);
          index += 1;
        }

        if (bonusList.isEmpty) {
          onError(_getLocalizedText('bonusProductsUnavailable'));
          return false;
        }

        addBonusProducts(bonusList);
        break;

      case 2:
        final rawValue = promocode.params?.discountValue ?? 0;
        final discountValue = rawValue / 100.0;

        if (discountValue <= 0) {
          onError(_getLocalizedText('invalidPromocode'));
          return false;
        }

        setPromocodePrice(discountValue);
        break;

      case 3:
        final promocodeName =
            ((promocode.name?.split('\$').last) ?? '').toLowerCase().trim();

        if (promocodeName.startsWith('bday')) {
          final isValidBirthday = await _checkBirthday();
          if (!isValidBirthday) {
            onError(_getLocalizedText('promocodeValidOnlyOnBirthday'));
            return false;
          }
        }

        if (promocodeName.startsWith('first')) {
          final isFirstOrder = await _checkFirstOrder();
          if (!isFirstOrder) {
            onError(_getLocalizedText('promocodeValidOnlyForFirstOrder'));
            return false;
          }
        }

        final discountValue =
            promocode.params?.discountValue?.toDouble() ?? 0;
        if (discountValue <= 0) {
          onError(_getLocalizedText('invalidPromocode'));
          return false;
        }

        final conditions = promocode.params?.conditions ?? [];
        final hasSpecificCondition = conditions.any(
          (condition) =>
              condition.type == 1 ||
              condition.type == 2 ||
              condition.type == 3,
        );
        final isSetOnly = promocode.params?.isSetOnly ?? false;

        if (isSetOnly || hasSpecificCondition) {
          setDiscountPromocodeProduct(discountValue);
        } else {
          setDiscountPromocode(discountValue);
        }
        break;

      case 4:
        // Fixed prices handled during total calculation.
        break;

      default:
        onError(_getLocalizedText('unsupportedPromocodeType'));
        return false;
    }
    return true;
  }

  Future<bool> _checkBirthday() async {
    try {
      // First check if user is logged in - similar to JSX auth check
      if (!User.isKeyAvalible('id')) {
        print('No user logged in for birthday check');
        return false;
      }

      // Get birthday from local user data first (like JSX gets from auth?.birthday)
      String? birthdayStr;

      // Try to get birthday from local storage first
      if (User.isKeyAvalible('birthday')) {
        birthdayStr = User.getUserInfo('birthday');
      }

      // If no local birthday data, get from server
      if (birthdayStr == null || birthdayStr.isEmpty) {
        if (!User.isKeyAvalible('phone') || !User.isKeyAvalible('password')) {
          print('No phone/password for API call');
          return false;
        }

        final clientInfo = await Api.getClient(
          User.getUserInfo('phone'),
          User.getUserInfo('password'),
        );

        if (clientInfo['res'] != true) {
          print('Failed to get client info from API');
          return false;
        }

        birthdayStr = clientInfo['birthday'];
      }

      if (birthdayStr == null || birthdayStr.isEmpty) {
        print('No birthday data available');
        return false;
      }

      // Parse birthday - handle multiple date formats like JSX does
      DateTime? birthday;

      // Try different parsing approaches
      try {
        // First try direct parsing
        birthday = DateTime.tryParse(birthdayStr);

        // If that fails, try parsing as MM/DD/YYYY or DD/MM/YYYY format
        if (birthday == null && birthdayStr.contains('/')) {
          final parts = birthdayStr.split('/');
          if (parts.length >= 3) {
            // Try MM/DD/YYYY format first
            try {
              final month = int.parse(parts[0]);
              final day = int.parse(parts[1]);
              final year = int.parse(parts[2]);
              birthday = DateTime(year, month, day);
            } catch (e) {
              // Try DD/MM/YYYY format
              try {
                final day = int.parse(parts[0]);
                final month = int.parse(parts[1]);
                final year = int.parse(parts[2]);
                birthday = DateTime(year, month, day);
              } catch (e) {
                print('Failed to parse date format: $birthdayStr');
              }
            }
          }
        }

        // Try parsing as timestamp if it's a number
        if (birthday == null) {
          final timestamp = int.tryParse(birthdayStr);
          if (timestamp != null) {
            birthday = DateTime.fromMillisecondsSinceEpoch(timestamp);
          }
        }
      } catch (e) {
        print('Error parsing birthday: $e');
      }

      if (birthday == null) {
        print('Could not parse birthday: $birthdayStr');
        return false;
      }

      final today = DateTime.now();

      // Match JSX logic exactly: compare month and day (ignore year)
      final isValidBirthday =
          today.month == birthday.month && today.day == birthday.day;

      print(
          'Birthday check: today=${today.month}/${today.day}, birthday=${birthday.month}/${birthday.day}, valid=$isValidBirthday');

      return isValidBirthday;
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

  bool isPromocodeActiveNow(Promocode promocode) {
    return _isPromocodeActiveNow(promocode);
  }

  bool _isPromocodeActiveNow(Promocode promocode) {
    final params = promocode.params;
    if (params == null) return true;

    final now = DateTime.now();
    final currentWeekDay = now.weekday;

    final allowedWeekDays = params.weekDays;
    if (allowedWeekDays != null && allowedWeekDays.isNotEmpty) {
      if (!allowedWeekDays.contains(currentWeekDay)) {
        print(
            'Promocode ${promocode.name} inactive on weekday $currentWeekDay');
        return false;
      }
    }

    final periods = params.periods;
    if (periods != null && periods.isNotEmpty) {
      final minuteOfDay = now.hour * 60 + now.minute;
      final matches =
          periods.any((period) => period.containsMinute(minuteOfDay));
      if (!matches) {
        print('Promocode ${promocode.name} inactive: outside allowed periods');
        return false;
      }
    }

    return true;
  }

  void validatePromocodeOnCartChange() {
    if (activePromocode.value != null && !isProcessing.value) {
      // If cart is empty, remove any active promocode immediately
      try {
        if (Order.getOrderLength() == 0) {
          print('Cart is empty, removing active promocode');
          handleRemovePromo();
          return;
        }
      } catch (_) {}

      print('Validating promocode on cart change');
      _validateCurrentPromocode();
    }
  }

  void _validateCurrentPromocode() {
    if (activePromocode.value == null || isProcessing.value) return;

    try {
      final promocode = activePromocode.value!;
      if (!_isPromocodeActiveNow(promocode)) {
        print('Promocode ${promocode.name} no longer active due to schedule');
        handleRemovePromo();
        return;
      }

      final orders = Order.getFullOrder();
      final regularOrders =
          orders.where((order) => order['promocode'] != true).toList();
      final normalizedOrders = regularOrders
          .whereType<Map>()
          .map((entry) => entry.cast<dynamic, dynamic>())
          .toList();

      final evaluation = _evaluateConditions(
        promocode,
        normalizedOrders,
        productsData: _cachedProductsData,
        categoriesData: _cachedCategoriesData,
      );

      if (evaluation.results.isNotEmpty) {
        final rule = (promocode.params?.conditionsRule ?? 'and').toLowerCase();
        final requiredMatches = promocode.params?.conditionsExactly ?? 0;
        final satisfiedCount =
            evaluation.results.where((value) => value).length;
        final meetsRule = _evaluateConditionsRule(
          evaluation.results,
          rule,
          requiredMatches,
        );

        if (!meetsRule) {
          print('Promocode ${promocode.name} failed conditions rule "$rule": '
              '$satisfiedCount of ${evaluation.results.length} conditions satisfied');
          handleRemovePromo();
          return;
        }
      }

      // Check if bonus products are still in cart for bonus type promocodes
      if (promocode.params?.resultType == 1) {
        final bonusProductsInCart =
            orders.where((order) => order['promocode'] == true).toList();
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
        final priceString =
            order['price']?.toString().replaceAll(' ', '') ?? '0';
        final price = int.tryParse(priceString) ?? 0;
        final amount = int.tryParse(order['amount']?.toString() ?? '1') ?? 1;
        total += price * amount;
      } catch (e) {
        print('Error calculating order total: $e');
      }
    }
    return total;
  }

  bool _evaluateConditionsRule(
    List<bool> conditionResults,
    String rule,
    int requiredMatches,
  ) {
    if (conditionResults.isEmpty) {
      return true;
    }

    final normalizedRule = (rule.isNotEmpty ? rule : 'and').toLowerCase();
    final satisfiedCount = conditionResults.where((value) => value).length;

    bool meetsRule;
    switch (normalizedRule) {
      case 'or':
        meetsRule = conditionResults.any((value) => value);
        break;
      case 'xor':
        meetsRule = satisfiedCount == 1;
        break;
      default:
        meetsRule = conditionResults.every((value) => value);
        break;
    }

    if (requiredMatches > 0) {
      meetsRule = meetsRule && satisfiedCount >= requiredMatches;
    }

    return meetsRule;
  }

  _ConditionsEvaluation _evaluateConditions(
    Promocode promocode,
    List<Map<dynamic, dynamic>> regularOrders, {
    List<dynamic>? productsData,
    List<dynamic>? categoriesData,
  }) {
    final params = promocode.params;
    if (params == null) {
      return const _ConditionsEvaluation(results: <bool>[]);
    }

    final activeConditions = (params.conditions ?? [])
        .where((condition) => condition.active != false)
        .toList();

    if (activeConditions.isEmpty) {
      return const _ConditionsEvaluation(results: <bool>[]);
    }

    final resolvedProducts = productsData ?? _cachedProductsData;
    final resolvedCategories = categoriesData ?? _cachedCategoriesData;
    final totalSum = _calculateRegularOrderTotal(regularOrders);
    final totalQuantity = _calculateTotalOrderQuantity(regularOrders);

    final results = <bool>[];
    String? firstFailureMessage;

    for (final condition in activeConditions) {
      final evaluation = _evaluateSingleCondition(
        condition,
        regularOrders,
        totalSum,
        totalQuantity,
        resolvedProducts,
        resolvedCategories,
      );
      results.add(evaluation.isSatisfied);
      if (!evaluation.isSatisfied && firstFailureMessage == null) {
        firstFailureMessage = evaluation.failureMessage;
      }
    }

    return _ConditionsEvaluation(
      results: results,
      firstFailureMessage: firstFailureMessage,
    );
  }

  _ConditionCheckResult _evaluateSingleCondition(
    Condition condition,
    List<Map<dynamic, dynamic>> regularOrders,
    int totalSum,
    int totalQuantity,
    List<dynamic>? productsData,
    List<dynamic>? categoriesData,
  ) {
    final conditionType = condition.type ?? 0;
    final requiredSumRaw = condition.sum ?? 0;
    final requiredSum = requiredSumRaw ~/ 100;
    final requiredQuantity = condition.pcs ?? 0;
    final requiredWeight = condition.grams ?? 0;

    switch (conditionType) {
      case 0:
        final meetsSum =
            requiredSum <= 0 ? true : totalSum >= requiredSum;
        final meetsQuantity =
            requiredQuantity <= 0 ? true : totalQuantity >= requiredQuantity;

        if (meetsSum && meetsQuantity) {
          return const _ConditionCheckResult(true);
        }

        if (!meetsSum) {
          final message =
              '${makePriceSomString(requiredSum)} ${_getLocalizedText('som')} ${_getLocalizedText('minimumOrderAmount')}';
          return _ConditionCheckResult(false, message);
        }

        final message =
            '${_getLocalizedText('addProductToCart')}';
        return _ConditionCheckResult(false, message);

      case 1:
        return _evaluateCategoryCondition(
          condition,
          regularOrders,
          requiredSum,
          requiredQuantity,
          requiredWeight,
          productsData,
          categoriesData,
        );

      case 2:
      case 3:
        return _evaluateProductCondition(
          condition,
          regularOrders,
          requiredSum,
          requiredQuantity,
          requiredWeight,
          productsData,
        );

      default:
        return const _ConditionCheckResult(true);
    }
  }

  _ConditionCheckResult _evaluateCategoryCondition(
    Condition condition,
    List<Map<dynamic, dynamic>> regularOrders,
    int requiredSum,
    int requiredQuantity,
    int requiredWeight,
    List<dynamic>? productsData,
    List<dynamic>? categoriesData,
  ) {
    final categoryId = condition.id?.toString() ?? '';
    if (categoryId.isEmpty) {
      return const _ConditionCheckResult(true);
    }

    final matchingOrders = regularOrders.where((order) {
      final productId = order['productId']?.toString() ?? '';
      if (productId.isEmpty) return false;
      return _isProductInCategoryTree(
        productId,
        categoryId,
        productsData: productsData,
      );
    }).toList();

    if (matchingOrders.isEmpty) {
      final categoryName = _resolveCategoryName(categoryId, categoriesData);
      final message =
          '${_getLocalizedText('addProductToCart')} ${categoryName ?? _getLocalizedText('category')}';
      return _ConditionCheckResult(false, message);
    }

    final categorySum = matchingOrders.fold<int>(
      0,
      (sum, order) => sum + _calculateOrderLineTotal(order),
    );
    final categoryQuantity = _calculateTotalOrderQuantity(matchingOrders);
    final categoryWeight =
        _calculateTotalWeight(matchingOrders, productsData: productsData);

    final meetsSum =
        requiredSum <= 0 ? true : categorySum >= requiredSum;
    final meetsQuantity =
        requiredQuantity <= 0 ? true : categoryQuantity >= requiredQuantity;
    final meetsWeight =
        requiredWeight <= 0 ? true : categoryWeight >= requiredWeight;

    if (meetsSum && meetsQuantity && meetsWeight) {
      return const _ConditionCheckResult(true);
    }

    final categoryName = _resolveCategoryName(categoryId, categoriesData) ??
        _getLocalizedText('category');

    if (!meetsSum) {
      final message =
          '${makePriceSomString(requiredSum)} ${_getLocalizedText('som')} ${_getLocalizedText('minimumOrderAmount')} - $categoryName';
      return _ConditionCheckResult(false, message);
    }

    if (!meetsQuantity) {
      final message =
          '${_getLocalizedText('addProductToCart')} $categoryName (x$requiredQuantity)';
      return _ConditionCheckResult(false, message);
    }

    final message =
        '${_getLocalizedText('addProductToCart')} $categoryName';
    return _ConditionCheckResult(false, message);
  }

  _ConditionCheckResult _evaluateProductCondition(
    Condition condition,
    List<Map<dynamic, dynamic>> regularOrders,
    int requiredSum,
    int requiredQuantity,
    int requiredWeight,
    List<dynamic>? productsData,
  ) {
    final productId =
        condition.id?.toString() ?? condition.productId?.toString() ?? '';
    if (productId.isEmpty) {
      return const _ConditionCheckResult(true);
    }

    final matchingOrders = regularOrders
        .where((order) => order['productId']?.toString() == productId)
        .toList();

    final productData = _findProductData(
      productId,
      productsData: productsData,
    );
    final localizedName = _getLocalizedProductName(productData);
    final label = localizedName.isNotEmpty
        ? localizedName
        : _getLocalizedText('products');

    if (matchingOrders.isEmpty) {
      final message =
          '${_getLocalizedText('addProductToCart')} $label';
      return _ConditionCheckResult(false, message);
    }

    final productSum = matchingOrders.fold<int>(
      0,
      (sum, order) => sum + _calculateOrderLineTotal(order),
    );
    final productQuantity = _calculateTotalOrderQuantity(matchingOrders);
    final productWeight =
        _calculateTotalWeight(matchingOrders, productsData: productsData);

    final meetsSum =
        requiredSum <= 0 ? true : productSum >= requiredSum;
    final meetsQuantity =
        requiredQuantity <= 0 ? true : productQuantity >= requiredQuantity;
    final meetsWeight =
        requiredWeight <= 0 ? true : productWeight >= requiredWeight;

    if (meetsSum && meetsQuantity && meetsWeight) {
      return const _ConditionCheckResult(true);
    }

    if (!meetsSum) {
      final message =
          '${makePriceSomString(requiredSum)} ${_getLocalizedText('som')} ${_getLocalizedText('minimumOrderAmount')} - $label';
      return _ConditionCheckResult(false, message);
    }

    if (!meetsQuantity) {
      final message =
          '${_getLocalizedText('addProductToCart')} $label (x$requiredQuantity)';
      return _ConditionCheckResult(false, message);
    }

    final message =
        '${_getLocalizedText('addProductToCart')} $label';
    return _ConditionCheckResult(false, message);
  }

  int _calculateTotalOrderQuantity(List<Map<dynamic, dynamic>> orders) {
    int total = 0;
    for (final order in orders) {
      final amount = int.tryParse(order['amount']?.toString() ?? '1') ?? 1;
      total += amount;
    }
    return total;
  }

  double _calculateTotalWeight(
    List<Map<dynamic, dynamic>> orders, {
    List<dynamic>? productsData,
  }) {
    double total = 0;
    for (final order in orders) {
      final productId = order['productId']?.toString();
      if (productId == null || productId.isEmpty) continue;

      final weight = _getProductWeight(productId, productsData: productsData);
      if (weight == null || weight <= 0) continue;

      final amount = int.tryParse(order['amount']?.toString() ?? '1') ?? 1;
      total += weight * amount;
    }
    return total;
  }

  Map<String, dynamic>? _findProductData(
    String productId, {
    List<dynamic>? productsData,
  }) {
    final source = productsData ?? _cachedProductsData;
    if (source == null) return null;

    for (final product in source) {
      if (product is! Map) continue;
      final id = product['product_id']?.toString();
      if (id == productId) {
        return product.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
    }
    return null;
  }

  String? _resolveCategoryName(
    String categoryId,
    List<dynamic>? categoriesData,
  ) {
    final source = categoriesData ?? _cachedCategoriesData;
    if (source == null) return null;

    for (final category in source) {
      if (category is! Map) continue;
      final id = category['category_id']?.toString();
      if (id == categoryId) {
        final rawName = category['category_name']?.toString() ?? '';
        if (rawName.isEmpty) return null;
        if (rawName.contains('***')) {
          return splitText(rawName);
        }
        return rawName;
      }
    }
    return null;
  }

  double? _getProductWeight(
    String productId, {
    List<dynamic>? productsData,
  }) {
    final product = _findProductData(
      productId,
      productsData: productsData,
    );
    if (product == null) return null;

    final out = product['out'];
    if (out is num) return out.toDouble();
    if (out is String) {
      final normalized = out.replaceAll(RegExp(r'[^0-9\\.,]'), '');
      if (normalized.isEmpty) return null;
      final parsed = double.tryParse(normalized.replaceAll(',', '.'));
      return parsed;
    }
    return null;
  }

  int? _getPosterPriceMinor(
    String productId, {
    List<dynamic>? productsData,
  }) {
    final product = _findProductData(
      productId,
      productsData: productsData,
    );
    if (product == null) return null;

    final priceData = product['price'];
    if (priceData is Map) {
      dynamic candidate;
      if (priceData.containsKey('1')) {
        candidate = priceData['1'];
      } else if (priceData.isNotEmpty) {
        candidate = priceData.values.first;
      }
      if (candidate is num) return candidate.toInt();
      if (candidate is String) return int.tryParse(candidate);
    } else if (priceData is num) {
      return priceData.toInt();
    } else if (priceData is String) {
      return int.tryParse(priceData);
    }
    return null;
  }

  int? _getPosterPriceAppUnits(
    String productId, {
    List<dynamic>? productsData,
  }) {
    final minor = _getPosterPriceMinor(
      productId,
      productsData: productsData,
    );
    if (minor == null) return null;
    return _posterMinorToAppUnits(minor);
  }

  int _posterMinorToAppUnits(num value) {
    return (value / 100).round();
  }

  int _normalizePosterValue(num value) {
    if (value >= 1000 || value <= -1000) {
      return _posterMinorToAppUnits(value);
    }
    return value.round();
  }

  Future<bool> _isClientInRequiredGroups(List<String> requiredGroups) async {
    if (requiredGroups.isEmpty) return true;
    if (!User.isKeyAvalible('id')) return false;

    try {
      final clientId = User.getUserInfo('id');
      if (clientId.isEmpty || clientId.trim().isEmpty) {
        return false;
      }

      final clientData = await Api.getPosterClient(clientId);
      if (clientData == null || clientData.isEmpty) {
        return false;
      }

      final rawGroups = clientData['client_groups_id'] ??
          clientData['client_groups_id_client'] ??
          clientData['client_groups'] ??
          clientData['groups'];

      final clientGroups = _normalizeGroupIds(rawGroups);

      if (clientGroups.isEmpty) {
        return false;
      }

      return clientGroups.any(requiredGroups.contains);
    } catch (e) {
      print('Error checking client groups: $e');
      return false;
    }
  }

  List<String> _normalizeGroupIds(dynamic source) {
    final result = <String>{};
    if (source == null) return <String>[];

    if (source is List) {
      for (final item in source) {
        final value = item?.toString().trim();
        if (value != null && value.isNotEmpty) {
          result.add(value);
        }
      }
      return result.toList();
    }

    if (source is Map) {
      source.forEach((key, value) {
        final normalizedKey = key?.toString().trim();
        final isActive = value is bool
            ? value
            : value is num
                ? value != 0
                : value?.toString().trim() == '1';
        if (normalizedKey != null && normalizedKey.isNotEmpty && isActive) {
          result.add(normalizedKey);
        }
      });
      return result.toList();
    }

    if (source is String) {
      final trimmed = source.trim();
      if (trimmed.isEmpty) return <String>[];
      final parts = trimmed.split(RegExp(r'[,\s;]+'));
      for (final part in parts) {
        final normalized = part.trim();
        if (normalized.isNotEmpty) {
          result.add(normalized);
        }
      }
      return result.toList();
    }

    result.add(source.toString());
    return result.toList();
  }

  int _calculateBonusUnitPrice({
    required int basePrice,
    required int? conditionType,
    required double? conditionValue,
  }) {
    switch (conditionType) {
      case 1:
        final percent = (conditionValue ?? 100).clamp(0, 100);
        final multiplier = (100 - percent) / 100;
        final discounted = (basePrice * multiplier).round();
        return discounted.clamp(0, basePrice);
      case 2:
        final discount = _normalizePosterValue(conditionValue ?? 0);
        final discounted = basePrice - discount;
        return discounted > 0 ? discounted : 0;
      case 3:
        final targetPrice = _normalizePosterValue(conditionValue ?? 0);
        return targetPrice.clamp(0, basePrice);
      default:
        return 0;
    }
  }

  double _calculateFixedPriceDiscount(
    Promocode promocode,
    List<Map<dynamic, dynamic>> orders, {
    List<dynamic>? productsData,
  }) {
    final discountPrices = promocode.params?.discountPrices;
    if (discountPrices == null || discountPrices.isEmpty) {
      return 0;
    }

    final sourcedProducts = productsData ?? _cachedProductsData;
    double totalDiscount = 0;

    for (final rule in discountPrices) {
      final targetType = rule.type ?? 0;
      final targetId = rule.id?.toString();
      final rawPrice = rule.price;
      if (targetId == null || rawPrice == null) continue;

      final targetPrice = _posterMinorToAppUnits(rawPrice);
      if (targetPrice <= 0) continue;

      for (final order in orders) {
        if (order['promocode'] == true) continue;

        final productId = order['productId']?.toString() ?? '';
        if (productId.isEmpty) continue;

        bool matches = false;
        if (targetType == 1) {
          matches = productId == targetId;
        } else if (targetType == 2) {
          matches = _isProductInCategoryTree(
            productId,
            targetId,
            productsData: sourcedProducts,
          );
        }

        if (!matches) continue;

        final unitPrice = int.tryParse(
              order['price']?.toString().replaceAll(' ', '') ?? '0',
            ) ??
            0;
        if (unitPrice <= 0) continue;

        final quantity = int.tryParse(order['amount']?.toString() ?? '1') ?? 1;
        if (quantity <= 0) continue;

        final discountPerUnit = (unitPrice - targetPrice).clamp(0, unitPrice);
        if (discountPerUnit <= 0) continue;

        totalDiscount += discountPerUnit * quantity;
      }
    }

    return totalDiscount;
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

  void _resetPromocodeDiscounts() {
    promocodePrice.value = 0;
    discountPromocode.value = 0;
    discountPromocodeProduct.value = 0;
    _savePromocodeState();
  }

  void _savePromocodeState() {
    try {
      if (_promocodeBox.isOpen) {
        if (activePromocode.value != null) {
          _promocodeBox.put(
              'active_promocode', jsonEncode(activePromocode.value!.toJson()));
        } else {
          _promocodeBox.delete('active_promocode');
        }
        _promocodeBox.put('promocode_price', promocodePrice.value);
        _promocodeBox.put('discount_promocode', discountPromocode.value);
        _promocodeBox.put(
            'discount_promocode_product', discountPromocodeProduct.value);
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
    final promocode = activePromocode.value;
    final bool limitToSets = _shouldLimitDiscountToSets(promocode);
    final Set<String> setCategoryIds = limitToSets
        ? _resolveSetCategoryIdsForPromo(promocode)
        : const <String>{};

    List<Map<dynamic, dynamic>>? cachedOrders;
    List<Map<dynamic, dynamic>> ensureOrders() {
      if (cachedOrders != null) return cachedOrders!;
      final rawOrders = Order.getFullOrder();
      cachedOrders = rawOrders
          .whereType<Map>()
          .map((entry) => entry.cast<dynamic, dynamic>())
          .toList();
      return cachedOrders!;
    }

    final promo = promocode;
    if (promo != null && promo.params?.resultType == 4) {
      final orders = ensureOrders();
      final discount = _calculateFixedPriceDiscount(
        promo,
        orders,
        productsData: _cachedProductsData,
      );
      if (discount > 0) {
        return (orderPrice - discount).clamp(0, double.infinity);
      }
    }

    // Absolute discount (sum off total)
    if (promocodePrice.value > 0) {
      if (limitToSets) {
        final orders = ensureOrders();
        final setSum = _calculateSetItemsSum(
          orders,
          explicitCategoryIds:
              setCategoryIds.isNotEmpty ? setCategoryIds : null,
          productsData: _cachedProductsData,
        );
        if (setSum <= 0) {
          return orderPrice;
        }
        final applicableDiscount = promocodePrice.value <= setSum
            ? promocodePrice.value
            : setSum.toDouble();
        return (orderPrice - applicableDiscount).clamp(0, double.infinity);
      }
      return (orderPrice - promocodePrice.value).clamp(0, double.infinity);
    }

    // Product/category-only percentage discount
    if (discountPromocodeProduct.value > 0 && promocode != null) {
      try {
        final orders = ensureOrders();
        final rawConditions = promocode.params?.conditions ?? [];
        final conditions = rawConditions
            .where((condition) => condition.active != false)
            .toList();

        final eligibleProductIds = <String>{};
        final eligibleCategoryIds = <String>{};

        for (final condition in conditions) {
          final conditionId = _normalizeId(condition.id);
          if (conditionId == null || conditionId.isEmpty) continue;

          if (condition.type == 2) {
            eligibleProductIds.add(conditionId);
          } else if (condition.type == 1) {
            eligibleCategoryIds.add(conditionId);
          }
        }

        if (limitToSets && setCategoryIds.isNotEmpty) {
          eligibleCategoryIds.addAll(setCategoryIds);
        }

        int eligibleSum = 0;
        final hasSpecificFilters =
            eligibleProductIds.isNotEmpty || eligibleCategoryIds.isNotEmpty;

        for (final order in orders) {
          if (order['promocode'] == true) continue;

          final productId = order['productId']?.toString() ?? '';
          if (productId.isEmpty) continue;

          bool include = false;

          if (eligibleProductIds.contains(productId)) {
            include = true;
          } else if (eligibleCategoryIds.isNotEmpty) {
            for (final categoryId in eligibleCategoryIds) {
              if (_isProductInCategoryTree(
                productId,
                categoryId,
                productsData: _cachedProductsData,
              )) {
                include = true;
                break;
              }
            }
          }

          if (!hasSpecificFilters) {
            include = true;
          }

          if (include && limitToSets) {
            include = _isProductSetItem(
              productId,
              explicitCategoryIds:
                  setCategoryIds.isNotEmpty ? setCategoryIds : null,
              productsData: _cachedProductsData,
            );
          }

          if (!include) continue;
          eligibleSum += _calculateOrderLineTotal(order);
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
      final percent = discountPromocode.value / 100.0;
      if (limitToSets) {
        final orders = ensureOrders();
        final setSum = _calculateSetItemsSum(
          orders,
          explicitCategoryIds:
              setCategoryIds.isNotEmpty ? setCategoryIds : null,
          productsData: _cachedProductsData,
        );
        final discount = setSum * percent;
        return (orderPrice - discount).clamp(0, double.infinity);
      }
      return orderPrice * (1 - percent);
    }

    return orderPrice;
  }

  double getDiscountAmount(double orderPrice) {
    if (!hasActivePromocode()) return 0;
    final adjustedTotal = getTotalPrice(orderPrice);
    final discount = orderPrice - adjustedTotal;
    return discount > 0 ? discount : 0;
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

  String _getLocalizedProductName(dynamic productData) {
    if (productData is Map) {
      final rawDescription =
          productData['product_production_description']?.toString() ?? '';
      if (rawDescription.isNotEmpty) {
        final sanitized = rawDescription.replaceAll('\n', '');
        final parts = sanitized.split('***');

        if (parts.length >= 6) {
          final localizedName = splitTextFromCategory(sanitized);
          if (localizedName.isNotEmpty) {
            return localizedName;
          }
        } else if (parts.length >= 3) {
          final localizedName = splitText(sanitized);
          if (localizedName.isNotEmpty) {
            return localizedName;
          }
        }
      }

      final rawName = productData['product_name']?.toString() ?? '';
      if (rawName.isNotEmpty) {
        if (rawName.contains('***')) {
          final localizedName = splitText(rawName);
          if (localizedName.isNotEmpty) {
            return localizedName;
          }
        }
        return rawName;
      }
    }

    return '';
  }

  // Helper method to get localized text
  String _getLocalizedText(String key) {
    final localization = FlutterLocalization.instance;

    String? currentCode = localization.currentLocale?.languageCode;
    if (currentCode == null || currentCode.isEmpty) {
      if (Language.isLanguageAvailable()) {
        currentCode = Language.getLanguage();
      }
    }

    Map<String, dynamic> translations;
    switch (currentCode) {
      case 'ru':
        translations = LocaleData.RU;
        break;
      case 'uz':
        translations = LocaleData.UZ;
        break;
      default:
        translations = LocaleData.EN;
        break;
    }

    final value = translations[key] ?? LocaleData.EN[key];
    if (value != null) {
      final normalized = value.toString();
      if (normalized.isNotEmpty) return normalized;
    }

    return key;
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

class _ConditionCheckResult {
  final bool isSatisfied;
  final String? failureMessage;

  const _ConditionCheckResult(this.isSatisfied, [this.failureMessage]);
}

class _ConditionsEvaluation {
  final List<bool> results;
  final String? firstFailureMessage;

  const _ConditionsEvaluation({
    required this.results,
    this.firstFailureMessage,
  });
}
