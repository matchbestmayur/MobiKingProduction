import 'package:hive/hive.dart';
import 'package:mobiking/app/data/product_model.dart';
import 'ParentCategory.dart';

part 'sub_category_model.g.dart'; // This will be generated

@HiveType(typeId: 0)
class SubCategory extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String slug;

  @HiveField(3)
  final int sequenceNo;

  @HiveField(4)
  final String? upperBanner;

  @HiveField(5)
  final String? lowerBanner;

  @HiveField(6)
  final bool active;

  @HiveField(7)
  final bool featured;

  @HiveField(8)
  final List<String> photos;

  @HiveField(9)
  final ParentCategory? parentCategory;

  @HiveField(10)
  final List<ProductModel> products;

  @HiveField(11)
  final DateTime createdAt;

  @HiveField(12)
  final DateTime updatedAt;

  @HiveField(13)
  final int v;

  @HiveField(14)
  final double? deliveryCharge;

  @HiveField(15)
  final int? minFreeDeliveryOrderAmount;

  @HiveField(16)
  final int? minOrderAmount;

  SubCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.sequenceNo,
    this.upperBanner,
    this.lowerBanner,
    required this.active,
    required this.featured,
    required this.photos,
    this.parentCategory,
    required this.products,
    required this.createdAt,
    required this.updatedAt,
    required this.v,
    this.deliveryCharge,
    this.minFreeDeliveryOrderAmount,
    this.minOrderAmount,
  });

  // Helper function to safely parse numbers into an int
  static int? _safeParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt(); // Convert double to int (truncates)
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  // Helper function to safely parse numbers into a double
  static double? _safeParseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble(); // Convert int to double
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      sequenceNo: _safeParseInt(json['sequenceNo']) ?? 0,
      upperBanner: json['upperBanner'] as String?,
      lowerBanner: json['lowerBanner'] as String?,
      active: json['active'] ?? false,
      featured: json['featured'] ?? false,
      photos: (json['photos'] as List?)?.map((e) => e.toString()).toList() ?? <String>[],
      parentCategory: json['parentCategory'] != null
          ? ParentCategory.fromJson(json['parentCategory'] as Map<String, dynamic>)
          : null,
      products: (json['products'] as List?)
          ?.map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList() ?? <ProductModel>[],
      createdAt: json['createdAt'] != null && json['createdAt'] is String
          ? DateTime.tryParse(json['createdAt']) ?? DateTime(2000)
          : DateTime(2000),
      updatedAt: json['updatedAt'] != null && json['updatedAt'] is String
          ? DateTime.tryParse(json['updatedAt']) ?? DateTime(2000)
          : DateTime(2000),
      v: _safeParseInt(json['__v']) ?? 0,
      deliveryCharge: _safeParseDouble(json['deliveryCharge']),
      minFreeDeliveryOrderAmount: _safeParseInt(json['minFreeDeliveryOrderAmount']),
      minOrderAmount: _safeParseInt(json['minOrderAmount']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'slug': slug,
      'sequenceNo': sequenceNo,
      'upperBanner': upperBanner,
      'lowerBanner': lowerBanner,
      'active': active,
      'featured': featured,
      'photos': photos,
      'parentCategory': parentCategory?.toJson(),
      'products': products.map((p) => p.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      '__v': v,
      'deliveryCharge': deliveryCharge,
      'minFreeDeliveryOrderAmount': minFreeDeliveryOrderAmount,
      'minOrderAmount': minOrderAmount,
    };
  }
}
