// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ParentCategory.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ParentCategoryAdapter extends TypeAdapter<ParentCategory> {
  @override
  final int typeId = 1;

  @override
  ParentCategory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ParentCategory(
      id: fields[0] as String,
      name: fields[1] as String,
      image: fields[2] as String,
      slug: fields[3] as String,
      active: fields[4] as bool,
      subCategories: (fields[5] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, ParentCategory obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.image)
      ..writeByte(3)
      ..write(obj.slug)
      ..writeByte(4)
      ..write(obj.active)
      ..writeByte(5)
      ..write(obj.subCategories);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParentCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
