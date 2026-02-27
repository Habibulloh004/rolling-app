import 'dart:convert';

class Promocode {
  final String? name;
  final int? id;
  final int? position;
  final bool accrualBonuses;
  final DateTime? dateStart;
  final DateTime? dateEnd;
  final bool autoApply;
  final PromocodeParams? params;

  Promocode({
    this.name,
    this.id,
    this.position,
    this.accrualBonuses = true,
    this.dateStart,
    this.dateEnd,
    this.autoApply = false,
    this.params,
  });

  factory Promocode.fromJson(Map<String, dynamic> json) {
    return Promocode(
      name: json['name']?.toString(),
      id: _parseInt(json['promotion_id']),
      position: _parseInt(json['position']),
      accrualBonuses: _parseBool(json['accrual_bonuses']) ?? true,
      dateStart: _parseDate(json['date_start']),
      dateEnd: _parseDate(json['date_end']),
      autoApply: _parseBool(json['auto_apply']) ?? false,
      params: json['params'] != null
          ? PromocodeParams.fromJson(json['params'] is String
              ? parsePromocodeParams(json['params'])
              : json['params'])
          : null,
    );
  }

  static Map<String, dynamic> parsePromocodeParams(String params) {
    try {
      return jsonDecode(params);
    } catch (e) {
      try {
        final uri = Uri.tryParse('?$params');
        if (uri != null) {
          return Map<String, dynamic>.from(uri.queryParameters);
        }
      } catch (e2) {
        print('Error parsing promocode params: $e2');
      }
      return {};
    }
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    final raw = value.toString().trim();
    if (raw.isEmpty || raw == '0000-00-00 00:00:00') {
      return null;
    }
    final normalized = raw.contains('T') ? raw : raw.replaceFirst(' ', 'T');
    try {
      return DateTime.parse(normalized);
    } catch (_) {
      return null;
    }
  }

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      switch (normalized) {
        case '1':
        case 'true':
        case 'yes':
        case 'on':
          return true;
        case '0':
        case 'false':
        case 'no':
        case 'off':
        case '':
          return false;
      }
    }
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'promotion_id': id,
      'position': position,
      'accrual_bonuses': accrualBonuses ? 1 : 0,
      'date_start': dateStart?.toIso8601String(),
      'date_end': dateEnd?.toIso8601String(),
      'auto_apply': autoApply ? 1 : 0,
      'params': params?.toJson(),
    };
  }
}

class PromocodeParams {
  final int? discountValue;
  final int?
      resultType; // 1: Bonus product, 2: Sum discount, 3: Percentage discount
  final int? clientsType; // 3: Only for auth users
  final List<String>? clientsGroups;
  final List<BonusProduct>? bonusProducts;
  final int? bonusProductsPcs;
  final int? bonusProductsGrams;
  final int? bonusProductsConditionType;
  final double? bonusProductsConditionValue;
  final int? bonusProductsAccumulation;
  final List<Condition>? conditions;
  final String? conditionsRule;
  final int? conditionsExactly;
  final List<int>? weekDays;
  final List<PromotionPeriod>? periods;
  final int? accumulationType;
  final int? accumulationChecksCount;
  final String? promoScope;
  final bool? setOnlyFlag;
  final List<String>? setCategoryIds;
  final List<String>? availableSpotIds;
  final List<PromotionDiscountPrice>? discountPrices;

  PromocodeParams({
    this.discountValue,
    this.resultType,
    this.clientsType,
    this.clientsGroups,
    this.bonusProducts,
    this.bonusProductsPcs,
    this.bonusProductsGrams,
    this.bonusProductsConditionType,
    this.bonusProductsConditionValue,
    this.bonusProductsAccumulation,
    this.conditions,
    this.conditionsRule,
    this.conditionsExactly,
    this.weekDays,
    this.periods,
    this.accumulationType,
    this.accumulationChecksCount,
    this.promoScope,
    this.setOnlyFlag,
    this.setCategoryIds,
    this.availableSpotIds,
    this.discountPrices,
  });

  factory PromocodeParams.fromJson(Map<String, dynamic> json) {
    return PromocodeParams(
      discountValue: _parseInt(json['discount_value']),
      resultType: _parseInt(json['result_type']),
      clientsType: _parseInt(json['clients_type']),
      clientsGroups: _parseStringList(json['clients_groups']),
      bonusProducts: json['bonus_products'] != null
          ? _parseBonusProducts(json['bonus_products'])
          : null,
      bonusProductsPcs: _parseInt(json['bonus_products_pcs']),
      bonusProductsGrams: _parseInt(json['bonus_products_g']),
      bonusProductsConditionType:
          _parseInt(json['bonus_products_condition_type']),
      bonusProductsConditionValue:
          _parseDouble(json['bonus_products_condition_value']),
      bonusProductsAccumulation:
          _parseInt(json['bonus_products_accumulation']),
      conditions: json['conditions'] != null
          ? _parseConditions(json['conditions'])
          : null,
      conditionsRule: json['conditions_rule']?.toString(),
      conditionsExactly: _parseInt(json['conditions_exactly']),
      weekDays: _parseWeekDays(json['week_days']),
      periods: _parsePeriods(json['periods']),
      accumulationType: _parseInt(json['accumulation_type']),
      accumulationChecksCount: _parseInt(json['accumulation_checks_count']),
      promoScope: _parsePromoScope(json),
      setOnlyFlag:
          _parseBool(json['set_only'] ?? json['setOnly'] ?? json['only_set']),
      setCategoryIds: _parseStringList(
        json['set_category_ids'] ??
            json['set_categories'] ??
            json['sets_category_ids'] ??
            json['sets_categories'] ??
            json['category_set_ids'] ??
            json['category_sets'],
      ),
      availableSpotIds: _parseSpotIds(json['available_for_spots']),
      discountPrices: _parseDiscountPrices(json['discount_prices']),
    );
  }

  bool get isSetOnly {
    if (setOnlyFlag == true) {
      return true;
    }

    if (setCategoryIds != null && setCategoryIds!.isNotEmpty) {
      return true;
    }

    final scopeRaw = promoScope;
    if (scopeRaw == null) return false;

    final normalizedScope = scopeRaw.toLowerCase().replaceAll('_', '-').trim();

    if (normalizedScope.isEmpty) return false;

    const directMatches = {
      'set-only',
      'setonly',
      'only-set',
      'only-sets',
      'sets-only',
      'sets',
      'set',
    };

    if (directMatches.contains(normalizedScope)) {
      return true;
    }

    return normalizedScope.contains('set');
  }

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      switch (normalized) {
        case '1':
        case 'true':
        case 'yes':
        case 'y':
        case 'on':
          return true;
        case '0':
        case 'false':
        case 'no':
        case 'n':
        case 'off':
        case '':
          return false;
      }
    }
    return null;
  }

  static String? _normalizeScopeValue(dynamic value) {
    if (value == null) return null;
    final normalized = value.toString().trim();
    if (normalized.isEmpty) return null;
    if (RegExp(r'^[0-9]+$').hasMatch(normalized)) {
      return null;
    }
    return normalized;
  }

  static String? _parsePromoScope(Map<String, dynamic> json) {
    const scopeKeys = [
      'promo_scope',
      'promocode_scope',
      'promotion_scope',
      'promo_type',
      'promotion_type',
      'discount_scope',
      'discount_type',
      'apply_to',
      'apply_scope',
      'target_scope',
      'target_type',
      'scope',
      'limit_to',
    ];

    for (final key in scopeKeys) {
      if (!json.containsKey(key)) continue;
      final value = _normalizeScopeValue(json[key]);
      if (value != null) {
        return value;
      }
    }

    final bool? setOnly =
        _parseBool(json['set_only'] ?? json['setOnly'] ?? json['only_set']);
    if (setOnly == true) {
      return 'set-only';
    }

    return null;
  }

  static List<String>? _parseStringList(dynamic data) {
    if (data == null) return null;

    final result = <String>{};

    if (data is List) {
      for (final item in data) {
        final normalized = item?.toString().trim();
        if (normalized != null && normalized.isNotEmpty) {
          result.add(normalized);
        }
      }
    } else if (data is Map) {
      data.forEach((key, value) {
        final isActive = _parseBool(value) ?? true;
        if (!isActive) return;
        final normalized = key?.toString().trim();
        if (normalized != null && normalized.isNotEmpty) {
          result.add(normalized);
        }
      });
    } else if (data is String) {
      final parts = data
          .split(RegExp(r'[,\s]+'))
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty);
      result.addAll(parts);
    } else {
      final normalized = data.toString().trim();
      if (normalized.isNotEmpty) {
        result.add(normalized);
      }
    }

    if (result.isEmpty) return null;
    return result.toList();
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final normalized = value.trim();
      if (normalized.isEmpty) return null;
      return double.tryParse(normalized.replaceAll(',', '.'));
    }
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static Map<String, dynamic>? _asJsonMap(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map(
        (key, dynamic v) => MapEntry(key.toString(), v),
      );
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      try {
        final decoded = jsonDecode(trimmed);
        return _asJsonMap(decoded);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static List<String>? _parseSpotIds(dynamic data) {
    if (data == null) return null;
    final result = <String>{};

    if (data is List) {
      for (final item in data) {
        final normalized = item?.toString().trim();
        if (normalized != null && normalized.isNotEmpty) {
          result.add(normalized);
        }
      }
    } else if (data is Map) {
      data.forEach((key, value) {
        final isActive = _parseBool(value) ?? false;
        if (isActive) {
          result.add(key.toString());
        }
      });
    } else if (data is String) {
      final parsed = _parseStringList(data);
      if (parsed != null) {
        result.addAll(parsed);
      }
    } else {
      result.add(data.toString());
    }

    if (result.isEmpty) return null;
    return result.toList();
  }

  static List<BonusProduct> _parseBonusProducts(dynamic products) {
    final result = <BonusProduct>[];

    void addProduct(dynamic value) {
      final map = _asJsonMap(value);
      if (map != null) {
        result.add(BonusProduct.fromJson(map));
      } else if (value != null) {
        result.add(BonusProduct(id: value.toString()));
      }
    }

    if (products is List) {
      for (final item in products) {
        addProduct(item);
      }
    } else if (products is Map) {
      products.forEach((key, value) {
        final base = _asJsonMap(value) ?? {};
        final map = Map<String, dynamic>.from(base);
        map.putIfAbsent('id', () => key.toString());
        if (!map.containsKey('count') && value is! Map) {
          map['count'] = value;
        }
        addProduct(map);
      });
    } else if (products != null) {
      addProduct(products);
    }
    return result;
  }

  static List<Condition> _parseConditions(dynamic conditions) {
    final result = <Condition>[];

    void addCondition(dynamic value) {
      final map = _asJsonMap(value);
      if (map != null) {
        result.add(Condition.fromJson(map));
      }
    }

    if (conditions is List) {
      for (final item in conditions) {
        addCondition(item);
      }
    } else if (conditions is Map) {
      conditions.forEach((key, value) {
        final base = _asJsonMap(value) ?? {};
        final map = Map<String, dynamic>.from(base);
        map.putIfAbsent('id', () => key.toString());
        addCondition(map);
      });
    } else if (conditions is String) {
      final trimmed = conditions.trim();
      if (trimmed.isNotEmpty) {
        try {
          final decoded = jsonDecode(trimmed);
          final parsed = _parseConditions(decoded);
          result.addAll(parsed);
        } catch (_) {}
      }
    } else if (conditions != null) {
      addCondition(conditions);
    }
    return result;
  }

  static bool? _parseActiveFlag(dynamic value,
      {bool allowNumericStrings = true}) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) {
      if (!allowNumericStrings) return null;
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (!allowNumericStrings && (normalized == '1' || normalized == '0')) {
        return null;
      }
      switch (normalized) {
        case '1':
        case 'true':
        case 'yes':
        case 'on':
          return true;
        case '0':
        case 'false':
        case 'no':
        case 'off':
        case '':
          return false;
      }
    }
    return null;
  }

  static List<int>? _parseWeekDays(dynamic data) {
    if (data == null) return null;

    final List<int> rawDays = [];

    void collectDay(int? day) {
      if (day == null) return;
      rawDays.add(day);
    }

    if (data is List) {
      final bool looksLikeMask = data.length == 7 &&
          data.every((item) => _parseActiveFlag(item) != null);

      if (looksLikeMask) {
        for (var i = 0; i < data.length; i++) {
          if (_parseActiveFlag(data[i]) == true) {
            collectDay(i);
          }
        }
      } else {
        for (var i = 0; i < data.length; i++) {
          final item = data[i];
          final activeFlag = _parseActiveFlag(item, allowNumericStrings: false);
          if (activeFlag == true) {
            collectDay(i);
            continue;
          }
          collectDay(_parseInt(item));
          if (item is String) {
            collectDay(_weekdayStringToIndex(item));
          }
        }
      }
    } else if (data is Map) {
      data.forEach((key, value) {
        final isActive = _parseActiveFlag(value) ?? false;
        if (!isActive) return;

        int? parsedKey;
        if (key is int) {
          parsedKey = key;
        } else {
          parsedKey = _parseInt(key);
        }

        collectDay(parsedKey);
        if (parsedKey == null && key is String) {
          collectDay(_weekdayStringToIndex(key));
        }
      });
    } else if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isNotEmpty) {
        try {
          final decoded = jsonDecode(trimmed);
          final parsed = _parseWeekDays(decoded);
          if (parsed != null) {
            rawDays.addAll(parsed);
          }
        } catch (_) {
          final separators = RegExp(r'[,\s]+');
          final tokens = trimmed
              .split(separators)
              .where((token) => token.isNotEmpty)
              .toList();

          final looksLikeMask = tokens.length == 7 &&
              tokens.every((token) => _parseActiveFlag(token) != null);

          if (looksLikeMask) {
            for (var i = 0; i < tokens.length; i++) {
              if (_parseActiveFlag(tokens[i]) == true) {
                collectDay(i);
              }
            }
          } else if (trimmed.length == 7 &&
              RegExp(r'^[01]+$').hasMatch(trimmed)) {
            for (var i = 0; i < trimmed.length; i++) {
              final char = trimmed.substring(i, i + 1);
              if (_parseActiveFlag(char) == true) {
                collectDay(i);
              }
            }
          } else {
            for (final token in tokens) {
              collectDay(int.tryParse(token));
              collectDay(_weekdayStringToIndex(token));
            }
          }
        }
      }
    }

    if (rawDays.isEmpty) return null;

    final bool looksZeroBased =
        rawDays.isNotEmpty && rawDays.every((day) => day >= 0 && day <= 6);
    final Set<int> normalizedDays = {};

    for (final raw in rawDays) {
      if (looksZeroBased) {
        final zeroBased =
            ((raw % 7) + 7) % 7; // keep within 0-6 even for negatives
        normalizedDays
            .add(zeroBased + 1); // convert to 1-7 where 1=Mon ... 7=Sun
      } else {
        final normalized = raw % 7;
        normalizedDays.add(normalized == 0 ? 7 : normalized);
      }
    }

    if (normalizedDays.isEmpty) return null;
    final result = normalizedDays.toList()..sort();
    return result;
  }

  static List<PromotionDiscountPrice>? _parseDiscountPrices(dynamic data) {
    if (data == null) return null;
    final result = <PromotionDiscountPrice>[];

    void addEntry(dynamic value) {
      final map = _asJsonMap(value);
      if (map == null) return;
      result.add(PromotionDiscountPrice.fromJson(map));
    }

    if (data is List) {
      for (final item in data) {
        addEntry(item);
      }
    } else if (data is Map) {
      data.forEach((key, value) {
        final map = _asJsonMap(value) ??
            {
              'id': key.toString(),
              'price': value,
            };
        map.putIfAbsent('id', () => key.toString());
        addEntry(map);
      });
    } else if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isNotEmpty) {
        try {
          final decoded = jsonDecode(trimmed);
          final parsed = _parseDiscountPrices(decoded);
          if (parsed != null) {
            result.addAll(parsed);
          }
        } catch (_) {}
      }
    } else {
      addEntry(data);
    }

    if (result.isEmpty) return null;
    return result;
  }

  static int? _weekdayStringToIndex(String value) {
    switch (value.toLowerCase()) {
      case 'mon':
      case 'monday':
        return 0;
      case 'tue':
      case 'tuesday':
        return 1;
      case 'wed':
      case 'wednesday':
        return 2;
      case 'thu':
      case 'thursday':
        return 3;
      case 'fri':
      case 'friday':
        return 4;
      case 'sat':
      case 'saturday':
        return 5;
      case 'sun':
      case 'sunday':
        return 6;
      default:
        return null;
    }
  }

  static List<PromotionPeriod>? _parsePeriods(dynamic data) {
    if (data == null) return null;

    final List<PromotionPeriod> result = [];

    void addPeriod(dynamic value) {
      if (value == null) return;
      final period = PromotionPeriod.fromJson(value);
      if (period.start != null || period.end != null) {
        result.add(period);
      }
    }

    if (data is List) {
      for (final item in data) {
        addPeriod(item);
      }
    } else if (data is Map) {
      data.forEach((_, value) {
        addPeriod(value);
      });
    } else if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isNotEmpty) {
        try {
          final decoded = jsonDecode(trimmed);
          final parsed = _parsePeriods(decoded);
          if (parsed != null) {
            result.addAll(parsed);
          }
        } catch (_) {
          final parts = trimmed.split(',');
          for (final part in parts) {
            final times = part.split('-');
            if (times.length >= 2) {
              addPeriod({
                'start': times[0].trim(),
                'end': times[1].trim(),
              });
            }
          }
        }
      }
    }

    if (result.isEmpty) return null;
    return result;
  }

  Map<String, dynamic> toJson() {
    return {
      'discount_value': discountValue,
      'result_type': resultType,
      'clients_type': clientsType,
      'clients_groups': clientsGroups,
      'bonus_products': bonusProducts?.map((e) => e.toJson()).toList(),
      'bonus_products_pcs': bonusProductsPcs,
      'bonus_products_g': bonusProductsGrams,
      'bonus_products_condition_type': bonusProductsConditionType,
      'bonus_products_condition_value': bonusProductsConditionValue,
      'bonus_products_accumulation': bonusProductsAccumulation,
      'conditions': conditions?.map((e) => e.toJson()).toList(),
      'conditions_rule': conditionsRule,
      'conditions_exactly': conditionsExactly,
      'week_days': _encodeWeekDaysMask(weekDays),
      'periods': periods?.map((e) => e.toJson()).toList(),
      'accumulation_type': accumulationType,
      'accumulation_checks_count': accumulationChecksCount,
      'promo_scope': promoScope,
      'set_only': setOnlyFlag,
      'set_category_ids': setCategoryIds,
      'available_for_spots': availableSpotIds,
      'discount_prices': discountPrices?.map((e) => e.toJson()).toList(),
    };
  }

  static List<String>? _encodeWeekDaysMask(List<int>? days) {
    if (days == null) return null;

    final mask = List<String>.filled(7, '0');
    for (final day in days) {
      var normalized = day % 7;
      if (normalized < 0) {
        normalized += 7;
      }
      if (normalized == 0) {
        normalized = 7;
      }
      final index = normalized - 1;
      if (index >= 0 && index < mask.length) {
        mask[index] = '1';
      }
    }
    return mask;
  }
}

class BonusProduct {
  final String? id;
  final int? type;
  final String? productId;
  final int? count;
  final List<Map<String, dynamic>>? bonusDishes;

  BonusProduct({
    this.id,
    this.type,
    this.productId,
    this.count,
    this.bonusDishes,
  });

  factory BonusProduct.fromJson(dynamic json) {
    final map = PromocodeParams._asJsonMap(json);
    if (map == null) {
      return BonusProduct(
        id: json?.toString(),
        count: 1,
      );
    }
    return BonusProduct(
      id: map['id']?.toString() ?? map['product_id']?.toString(),
      type: _parseInt(map['type']),
      productId: map['product_id']?.toString(),
      count: _parseInt(map['count'] ?? map['pcs'] ?? map['quantity']) ?? 1,
      bonusDishes: _parseBonusDishes(map['bonus_dishes']),
    );
  }

  static List<Map<String, dynamic>>? _parseBonusDishes(dynamic value) {
    if (value == null) return null;
    final result = <Map<String, dynamic>>[];
    if (value is List) {
      for (final item in value) {
        final map = PromocodeParams._asJsonMap(item);
        if (map != null) {
          result.add(map);
        }
      }
    } else if (value is Map) {
      result.add(
        value.map(
          (key, dynamic v) => MapEntry(key.toString(), v),
        ),
      );
    }
    if (result.isEmpty) return null;
    return result;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'product_id': productId,
      'count': count,
      if (bonusDishes != null) 'bonus_dishes': bonusDishes,
    };
  }
}

class Condition {
  final int? type; // 0: All products, 1: Category, 2: Product, 3: Product with modifiers
  final String? id;
  final String? productId;
  final int? pcs;
  final int? grams;
  final int? sum;
  final bool? active;

  Condition({
    this.type,
    this.id,
    this.productId,
    this.pcs,
    this.grams,
    this.sum,
    this.active,
  });

  factory Condition.fromJson(Map<String, dynamic> json) {
    final map = json.map(
      (key, value) => MapEntry(key.toString(), value),
    );
    return Condition(
      type: _parseInt(map['type']),
      id: map['id']?.toString() ??
          map['category_id']?.toString() ??
          map['product_id']?.toString(),
      productId: map['product_id']?.toString(),
      pcs: _parseInt(map['pcs'] ?? map['count']),
      grams: _parseInt(map['g'] ?? map['grams']),
      sum: _parseInt(map['sum'] ?? map['min_sum']),
      active: PromocodeParams._parseBool(map['active']) ?? true,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'id': id,
      'product_id': productId,
      'pcs': pcs,
      'g': grams,
      'sum': sum,
      'active': active,
    };
  }
}

class PromotionDiscountPrice {
  final int? type;
  final String? id;
  final int? price;

  PromotionDiscountPrice({
    this.type,
    this.id,
    this.price,
  });

  factory PromotionDiscountPrice.fromJson(Map<String, dynamic> json) {
    return PromotionDiscountPrice(
      type: PromocodeParams._parseInt(json['type']),
      id: json['id']?.toString(),
      price: PromocodeParams._parseInt(json['price']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'id': id,
      'price': price,
    };
  }
}

class PromotionPeriod {
  final String? start;
  final String? end;

  PromotionPeriod({this.start, this.end});

  factory PromotionPeriod.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return PromotionPeriod(
        start: (json['start'] ?? json['start_time'])?.toString(),
        end: (json['end'] ?? json['end_time'])?.toString(),
      );
    }

    if (json is List && json.length >= 2) {
      return PromotionPeriod(
        start: json[0]?.toString(),
        end: json[1]?.toString(),
      );
    }

    if (json is String) {
      final parts = json.split('-');
      if (parts.length >= 2) {
        return PromotionPeriod(
          start: parts[0].trim(),
          end: parts[1].trim(),
        );
      }
      return PromotionPeriod(start: json);
    }

    return PromotionPeriod();
  }

  Map<String, dynamic> toJson() {
    return {
      'start': start,
      'end': end,
    };
  }

  bool containsMinute(int minuteOfDay) {
    final startMinutes = _parseTimeToMinutes(start);
    final endMinutes = _parseTimeToMinutes(end);

    if (startMinutes == null || endMinutes == null) {
      return true;
    }

    if (startMinutes == endMinutes) {
      return minuteOfDay == startMinutes;
    }

    if (startMinutes < endMinutes) {
      return minuteOfDay >= startMinutes && minuteOfDay <= endMinutes;
    }

    return minuteOfDay >= startMinutes || minuteOfDay <= endMinutes;
  }

  static int? _parseTimeToMinutes(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return hour * 60 + minute;
  }
}
