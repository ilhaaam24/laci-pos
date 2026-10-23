import 'package:equatable/equatable.dart';

/// Represents a specific variant of a product (e.g. Size: Large, Suhu: Hot/Ice, Kaos: XL).
class ProductVariant extends Equatable {
  final String id;
  final String name;
  final double price;
  final double costPrice;
  final int stock;
  final String? sku;

  const ProductVariant({
    required this.id,
    required this.name,
    required this.price,
    this.costPrice = 0,
    this.stock = 0,
    this.sku,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'costPrice': costPrice,
    'stock': stock,
    if (sku != null) 'sku': sku,
  };

  factory ProductVariant.fromJson(Map<String, dynamic> json) => ProductVariant(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0.0,
    stock: (json['stock'] as num?)?.toInt() ?? 0,
    sku: json['sku'] as String?,
  );

  ProductVariant copyWith({
    String? id,
    String? name,
    double? price,
    double? costPrice,
    int? stock,
    String? sku,
  }) {
    return ProductVariant(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      stock: stock ?? this.stock,
      sku: sku ?? this.sku,
    );
  }

  @override
  List<Object?> get props => [id, name, price, costPrice, stock, sku];
}

/// Represents an option within a modifier group (e.g. "Boba (+4.000)", "Less Sugar (+0)").
class ModifierOption extends Equatable {
  final String id;
  final String name;
  final double price;
  final double costPrice;

  const ModifierOption({
    required this.id,
    required this.name,
    this.price = 0,
    this.costPrice = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'costPrice': costPrice,
  };

  factory ModifierOption.fromJson(Map<String, dynamic> json) => ModifierOption(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0.0,
  );

  ModifierOption copyWith({
    String? id,
    String? name,
    double? price,
    double? costPrice,
  }) {
    return ModifierOption(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
    );
  }

  @override
  List<Object?> get props => [id, name, price, costPrice];
}

/// Group of modifiers/add-ons/toppings (e.g. "Pilihan Topping", "Level Gula", "Level Pedas").
class ModifierGroup extends Equatable {
  final String id;
  final String name;
  final bool isRequired;
  final int minSelect;
  final int maxSelect;
  final List<ModifierOption> options;

  const ModifierGroup({
    required this.id,
    required this.name,
    this.isRequired = false,
    this.minSelect = 0,
    int maxSelect = 1,
    bool? allowMultiple,
    this.options = const [],
  }) : maxSelect = allowMultiple != null ? (allowMultiple ? 999 : 1) : maxSelect;

  bool get allowMultiple => maxSelect > 1;
  bool get isMultiple => allowMultiple;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isRequired': isRequired,
    'minSelect': minSelect,
    'maxSelect': maxSelect,
    'allowMultiple': allowMultiple,
    'options': options.map((o) => o.toJson()).toList(),
  };

  factory ModifierGroup.fromJson(Map<String, dynamic> json) {
    final allowMult = json['allowMultiple'] as bool?;
    final maxSel = (json['maxSelect'] as num?)?.toInt() ?? (allowMult == true ? 999 : 1);
    return ModifierGroup(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      isRequired: json['isRequired'] as bool? ?? false,
      minSelect: (json['minSelect'] as num?)?.toInt() ?? 0,
      maxSelect: maxSel,
      options: (json['options'] as List<dynamic>?)
              ?.map((o) => ModifierOption.fromJson(o as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  ModifierGroup copyWith({
    String? id,
    String? name,
    bool? isRequired,
    int? minSelect,
    int? maxSelect,
    bool? allowMultiple,
    List<ModifierOption>? options,
  }) {
    return ModifierGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      isRequired: isRequired ?? this.isRequired,
      minSelect: minSelect ?? this.minSelect,
      maxSelect: maxSelect ??
          (allowMultiple != null
              ? (allowMultiple ? 999 : 1)
              : this.maxSelect),
      options: options ?? this.options,
    );
  }

  @override
  List<Object?> get props => [id, name, isRequired, minSelect, maxSelect, options];
}

