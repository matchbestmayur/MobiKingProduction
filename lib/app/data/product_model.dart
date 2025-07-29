import 'package:hive/hive.dart';
import 'key_information.dart';
import 'order_model.dart' hide SellingPrice;
import 'selling_price.dart';


part 'product_model.g.dart';

@HiveType(typeId: 2)
class ProductModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String fullName;

  @HiveField(3)
  final String slug;

  @HiveField(4)
  final String description;

  @HiveField(5)
  final bool active;

  @HiveField(6)
  final bool newArrival;

  @HiveField(7)
  final bool liked;

  @HiveField(8)
  final bool bestSeller;

  @HiveField(9)
  final bool recommended;

  @HiveField(10)
  final List<SellingPrice> sellingPrice;

  @HiveField(11)
  final String categoryId;

  @HiveField(12)
  final List<String> stockIds;

  @HiveField(13)
  final List<String> orderIds;

  @HiveField(14)
  final List<String> groupIds;

  @HiveField(15)
  final int totalStock;

  @HiveField(16)
  final Map<String, int> variants;

  @HiveField(17)
  final List<String> images;

  @HiveField(18)
  final List<String> descriptionPoints;

  @HiveField(19)
  final List<KeyInformation> keyInformation;

  @HiveField(20)
  final int? regularPrice;

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
    this.regularPrice,
  });

  // ... rest of your fromJson and toJson methods stay the same
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
      if (regularPrice != null) 'regularPrice': regularPrice,
    };
  }
}
