import 'group_model.dart';
import 'category_model.dart'; // Assuming you have a CategoryModel defined

class HomeLayoutModel {
  final String id;
  final bool active;
  final List<String> banners;
  final List<GroupModel> groups;
  final List<CategoryModel> categories; // NEW: Add categories list

  HomeLayoutModel({
    required this.id,
    required this.active,
    required this.banners,
    required this.groups,
    required this.categories, // NEW: Add categories to constructor
  });

  factory HomeLayoutModel.fromJson(Map<String, dynamic> json) {
    final groupsJson = json['groups'];
    List<GroupModel> groupsList = [];

    if (groupsJson != null && groupsJson is List) {
      groupsList = groupsJson
          .where((e) => e is Map<String, dynamic>)
          .map((e) => GroupModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      print("Warning: groups is null or not a List: $groupsJson");
    }

    final bannersJson = json['banners'];
    List<String> bannersList = [];
    if (bannersJson != null && bannersJson is List) {
      bannersList = List<String>.from(bannersJson);
    } else {
      print("Warning: banners is null or not a List: $bannersJson");
    }

    // NEW: Parse categories from JSON
    final categoriesJson = json['categories'];
    List<CategoryModel> categoriesList = [];
    if (categoriesJson != null && categoriesJson is List) {
      categoriesList = categoriesJson
          .where((e) => e is Map<String, dynamic>)
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      print("Warning: categories is null or not a List: $categoriesJson");
    }
    // END NEW PARSING

    return HomeLayoutModel(
      id: json['_id'] ?? '',
      active: json['active'] ?? false,
      banners: bannersList,
      groups: groupsList,
      categories: categoriesList, // NEW: Pass parsed categories
    );
  }
}

// Updated CategoryModel with the 'icon' and 'theme' field
class CategoryModel {
  final String id;
  final String name;
  final String slug;
  final int sequenceNo;
  final String? upperBanner;
  final String? lowerBanner;
  final bool active;
  final bool featured;
  final List<String> photos;
  final String? parentCategory;
  final List<String> products;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? deliveryCharge; // ✅ changed from int? to double?
  final double? minFreeDeliveryOrderAmount; // ✅ changed
  final double? minOrderAmount; // ✅ changed
  final String? icon;
  final String? theme;

  CategoryModel({
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
    this.deliveryCharge,
    this.minFreeDeliveryOrderAmount,
    this.minOrderAmount,
    this.icon,
    this.theme,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      sequenceNo: json['sequenceNo'] as int? ?? 0,
      upperBanner: json['upperBanner'] as String?,
      lowerBanner: json['lowerBanner'] as String?,
      active: json['active'] as bool? ?? false,
      featured: json['featured'] as bool? ?? false,
      photos: List<String>.from(json['photos'] ?? []),
      parentCategory: json['parentCategory'] as String?,
      products: List<String>.from(json['products'] ?? []),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
      deliveryCharge: (json['deliveryCharge'] as num?)?.toDouble(), // ✅ safe cast
      minFreeDeliveryOrderAmount: (json['minFreeDeliveryOrderAmount'] as num?)?.toDouble(), // ✅ safe cast
      minOrderAmount: (json['minOrderAmount'] as num?)?.toDouble(), // ✅ safe cast
      icon: json['icon'] as String?,
      theme: json['theme'] as String?,
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
      'parentCategory': parentCategory,
      'products': products,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deliveryCharge': deliveryCharge,
      'minFreeDeliveryOrderAmount': minFreeDeliveryOrderAmount,
      'minOrderAmount': minOrderAmount,
      'icon': icon,
      'theme': theme,
    };
  }
}
