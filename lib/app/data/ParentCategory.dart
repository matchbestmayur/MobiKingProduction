import 'package:hive/hive.dart';

part 'ParentCategory.g.dart'; // ← Change to match your file name (capital P,

@HiveType(typeId: 1) // Using typeId 1 as mentioned in the previous conversation
class ParentCategory extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String image;

  @HiveField(3)
  final String slug;

  @HiveField(4)
  final bool active;

  @HiveField(5)
  final List<String> subCategories;

  ParentCategory({
    required this.id,
    required this.name,
    required this.image,
    required this.slug,
    required this.active,
    required this.subCategories,
  });

  factory ParentCategory.fromJson(Map<String, dynamic> json) {
    return ParentCategory(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      slug: json['slug'] ?? '',
      active: json['active'] ?? false,
      subCategories: json['subCategories'] != null
          ? List<String>.from(json['subCategories'])
          : <String>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'image': image,
      'slug': slug,
      'active': active,
      'subCategories': subCategories,
    };
  }
}
