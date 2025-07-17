import 'package:mobiking/app/data/product_model.dart';

class GroupModel {
  final String id;
  final String name;
  final int sequenceNo;
  final String banner;
  final bool active;
  final bool isBannerVisible; // Corrected field name
  final bool isSpecial;
  final List<ProductModel> products;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? backgroundColor; // Field for the actual background color string
  final bool
  isBackgroundColorVisible; // Field to control visibility of background color

  GroupModel({
    required this.id,
    required this.name,
    required this.sequenceNo,
    required this.banner,
    required this.active,
    required this.isBannerVisible,
    required this.isSpecial,
    required this.products,
    required this.createdAt,
    required this.updatedAt,
    this.backgroundColor, // Make optional
    required this.isBackgroundColorVisible, // This was in your initial JSON but not in the GroupModel fields list
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) => GroupModel(
    id: json['_id'] ?? '',
    name: json['name'] ?? '',
    sequenceNo: json['sequenceNo'] ?? 0,
    banner: json['banner'] ?? '',
    active: json['active'] ?? true,
    // **CORRECTED:** Using 'isBannerVisble' from JSON for consistency with your provided data
    // If your backend JSON key is actually 'isBannerVisible', change 'isBannerVisble' below.
    isBannerVisible: json['isBannerVisble'] ?? false,
    isSpecial: json['isSpecial'] ?? false,
    products: (json['products'] as List<dynamic>? ?? [])
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList(),
    createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    backgroundColor: json['backgroundColor'],
    // **ADDED:** Parsing the 'isBackgroundColorVisible' field
    isBackgroundColorVisible: json['isBackgroundColorVisible'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'sequenceNo': sequenceNo,
    'banner': banner,
    'active': active,
    'isBannerVisible': isBannerVisible,
    'isSpecial': isSpecial,
    'products': products.map((p) => p.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'backgroundColor': backgroundColor,
    'isBackgroundColorVisible': isBackgroundColorVisible,
  };
}