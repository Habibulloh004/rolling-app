import 'dart:convert';

class Promocode {
  final String? name;
  final int? id;
  final PromocodeParams? params;

  Promocode({
    this.name,
    this.id,
    this.params,
  });

  factory Promocode.fromJson(Map<String, dynamic> json) {
    return Promocode(
      name: json['name']?.toString(),
      id: _parseInt(json['promotion_id']),
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
      'params': params?.toJson(),
    };
  }
}

class PromocodeParams {
  final int? discountValue;
  final int? resultType; // 1: Bonus product, 2: Sum discount, 3: Percentage discount
  final int? clientsType; // 3: Only for auth users
  final List<BonusProduct>? bonusProducts;
  final int? bonusProductsPcs;
  final List<Condition>? conditions;

  PromocodeParams({
    this.discountValue,
    this.resultType,
    this.clientsType,
    this.bonusProducts,
    this.bonusProductsPcs,
    this.conditions,
  });

  factory PromocodeParams.fromJson(Map<String, dynamic> json) {
    return PromocodeParams(
      discountValue: _parseInt(json['discount_value']),
      resultType: _parseInt(json['result_type']),
      clientsType: _parseInt(json['clients_type']),
      bonusProducts: json['bonus_products'] != null
          ? _parseBonusProducts(json['bonus_products'])
          : null,
      bonusProductsPcs: _parseInt(json['bonus_products_pcs']),
      conditions: json['conditions'] != null
          ? _parseConditions(json['conditions'])
          : null,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static List<BonusProduct> _parseBonusProducts(dynamic products) {
    if (products is List) {
      return products.map((e) => BonusProduct.fromJson(e)).toList();
    } else if (products is Map) {
      return products.entries
          .map((e) => BonusProduct(id: e.key.toString(), count: _parseInt(e.value)))
          .toList();
    }
    return [];
  }

  static List<Condition> _parseConditions(dynamic conditions) {
    if (conditions is List) {
      return conditions.map((e) => Condition.fromJson(e)).toList();
    } else if (conditions is Map) {
      return conditions.entries
          .map((e) => Condition.fromJson({'id': e.key, ...e.value}))
          .toList();
    }
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'discount_value': discountValue,
      'result_type': resultType,
      'clients_type': clientsType,
      'bonus_products': bonusProducts?.map((e) => e.toJson()).toList(),
      'bonus_products_pcs': bonusProductsPcs,
      'conditions': conditions?.map((e) => e.toJson()).toList(),
    };
  }
}

class BonusProduct {
  final String? id;
  final int? count;

  BonusProduct({this.id, this.count});

  factory BonusProduct.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return BonusProduct(
        id: json['id']?.toString() ?? json['product_id']?.toString(),
        count: _parseInt(json['count'] ?? json['quantity'] ?? 1),
      );
    }
    return BonusProduct(id: json.toString(), count: 1);
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
      'count': count,
    };
  }
}

class Condition {
  final int? type; // 0: All products, 1: Category, 2: Product
  final String? id;
  final int? sum;
  final bool? active;

  Condition({this.type, this.id, this.sum, this.active});

  factory Condition.fromJson(Map<String, dynamic> json) {
    return Condition(
      type: _parseInt(json['type']),
      id: json['id']?.toString() ??
          json['category_id']?.toString() ??
          json['product_id']?.toString(),
      sum: _parseInt(json['sum'] ?? json['min_sum']),
      active: json['active'] ?? true,
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
      'sum': sum,
      'active': active,
    };
  }
}