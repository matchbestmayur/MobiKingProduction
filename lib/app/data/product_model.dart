class KeyInformation {
  final String title;
  final String content;

  KeyInformation({
    required this.title,
    required this.content,
  });

  factory KeyInformation.fromJson(Map<String, dynamic> json) {
    return KeyInformation(
      title: json['title'] ?? '',
      content: json['content'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'content': content,
  };
}

class SellingPrice {
  final String? id;
  final int price;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SellingPrice({
    this.id,
    required this.price,
    this.createdAt,
    this.updatedAt,
  });

  factory SellingPrice.fromJson(Map<String, dynamic> json) {
    return SellingPrice(
      id: json['_id'] as String?,
      price: (json['price'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) '_id': id,
    'price': price,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };
}

class ProductModel {
  final String id;
  final String name;
  final String fullName;
  final String slug;
  final String description;
  final bool active;
  final bool newArrival;
  final bool liked;
  final bool bestSeller;
  final bool recommended;
  final List<SellingPrice> sellingPrice;
  final String categoryId;
  final List<String> stockIds;
  final List<String> orderIds;
  final List<String> groupIds;
  final int totalStock;
  final Map<String, int> variants;
  final List<String> images;
  final List<String> descriptionPoints;
  final List<KeyInformation> keyInformation;
  final int? regularPrice; // <--- NEW FIELD: Added as nullable int

  ProductModel({
    required this.id,
    required this.name,
    required this.fullName,
    required this.slug,
    required this.description,
    required this.active,
    required this.newArrival,
    required this.liked,
    required this.bestSeller,
    required this.recommended,
    required this.sellingPrice,
    required this.categoryId,
    required this.stockIds,
    required this.orderIds,
    required this.groupIds,
    required this.totalStock,
    required this.variants,
    required this.images,
    required this.descriptionPoints,
    required this.keyInformation,
    this.regularPrice, // <--- ADDED to constructor
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      fullName: json['fullName'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      active: json['active'] ?? false,
      newArrival: json['newArrival'] ?? false,
      liked: json['liked'] ?? false,
      bestSeller: json['bestSeller'] ?? false,
      recommended: json['recommended'] ?? false,
      sellingPrice: (json['sellingPrice'] as List<dynamic>? ?? [])
          .map((e) => SellingPrice.fromJson(e))
          .toList(),
      categoryId: (json['category'] != null && json['category'] is Map)
          ? (json['category']['_id'] as String? ?? '')
          : (json['category'] is String ? json['category'] as String : ''),
      stockIds: (json['stock'] as List<dynamic>? ?? [])
          .map((e) => e is Map ? (e['_id'] as String? ?? '') : e.toString())
          .where((id) => id.isNotEmpty)
          .toList(),
      orderIds: (json['orders'] as List<dynamic>? ?? [])
          .map((e) => e is Map ? (e['_id'] as String? ?? '') : e.toString())
          .where((id) => id.isNotEmpty)
          .toList(),
      groupIds: (json['groups'] as List<dynamic>? ?? [])
          .map((e) => e is Map ? (e['_id'] as String? ?? '') : e.toString())
          .where((id) => id.isNotEmpty)
          .toList(),
      totalStock: json['totalStock'] ?? 0,
      variants: Map<String, int>.from(json['variants'] as Map? ?? {}),
      images: List<String>.from(json['images'] ?? []),
      descriptionPoints: List<String>.from(json['descriptionPoints'] ?? []),
      keyInformation: (json['keyInformation'] as List<dynamic>? ?? [])
          .map((e) => KeyInformation.fromJson(e))
          .toList(),
      regularPrice: (json['regularPrice'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'fullName': fullName,
      'slug': slug,
      'description': description,
      'active': active,
      'newArrival': newArrival,
      'liked': liked,
      'bestSeller': bestSeller,
      'recommended': recommended,
      'sellingPrice': sellingPrice.map((e) => e.toJson()).toList(),
      'categoryId': categoryId,
      'stockIds': stockIds,
      'orderIds': orderIds,
      'groupIds': groupIds,
      'totalStock': totalStock,
      'variants': variants,
      'images': images,
      'descriptionPoints': descriptionPoints,
      'keyInformation': keyInformation.map((e) => e.toJson()).toList(),
      if (regularPrice != null) 'regularPrice': regularPrice, // <--- ADDED to toJson, conditionally
    };
  }
}