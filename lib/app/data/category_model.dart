import 'package:hive/hive.dart';

part 'category_model.g.dart';

@HiveType(typeId: 5) // Using typeId 5 to continue the sequence
class CategoryModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String slug;

  @HiveField(3)
  final bool active;

  @HiveField(4)
  final String? image; // nullable as in your original

  @HiveField(5)
  final List<String> subCategoryIds;

  CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.active,
    required this.image,
    required this.subCategoryIds,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    List<String> subCategoryIds = [];
    if (json['subCategories'] != null) {
      subCategoryIds = List<String>.from(
        (json['subCategories'] as List).map(
              (e) => e is String ? e : e['_id'] ?? '',
        ),
      );
      subCategoryIds.removeWhere((id) => id.isEmpty);
    }

    return CategoryModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      active: json['active'] ?? false,
      image: json['image'] as String?, // safely cast
      subCategoryIds: subCategoryIds,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'slug': slug,
    'active': active,
    'image': image,
    'subCategories': subCategoryIds,
  };
}
