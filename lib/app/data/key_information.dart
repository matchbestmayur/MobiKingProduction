import 'package:hive/hive.dart';

part 'key_information.g.dart';

@HiveType(typeId: 3)
class KeyInformation extends HiveObject {
  @HiveField(0)
  final String title;

  @HiveField(1)
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
