// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sub_category_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SubCategoryAdapter extends TypeAdapter<SubCategory> {
  @override
  final int typeId = 0;

  @override
  SubCategory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SubCategory(
      id: fields[0] as String,
      name: fields[1] as String,
      slug: fields[2] as String,
      sequenceNo: fields[3] as int,
      upperBanner: fields[4] as String?,
      lowerBanner: fields[5] as String?,
      active: fields[6] as bool,
      featured: fields[7] as bool,
      photos: (fields[8] as List).cast<String>(),
      parentCategory: fields[9] as ParentCategory?,
      products: (fields[10] as List).cast<ProductModel>(),
      createdAt: fields[11] as DateTime,
      updatedAt: fields[12] as DateTime,
      v: fields[13] as int,
      deliveryCharge: fields[14] as double?,
      minFreeDeliveryOrderAmount: fields[15] as int?,
      minOrderAmount: fields[16] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, SubCategory obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.slug)
      ..writeByte(3)
      ..write(obj.sequenceNo)
      ..writeByte(4)
      ..write(obj.upperBanner)
      ..writeByte(5)
      ..write(obj.lowerBanner)
      ..writeByte(6)
      ..write(obj.active)
      ..writeByte(7)
      ..write(obj.featured)
      ..writeByte(8)
      ..write(obj.photos)
      ..writeByte(9)
      ..write(obj.parentCategory)
      ..writeByte(10)
      ..write(obj.products)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt)
      ..writeByte(13)
      ..write(obj.v)
      ..writeByte(14)
      ..write(obj.deliveryCharge)
      ..writeByte(15)
      ..write(obj.minFreeDeliveryOrderAmount)
      ..writeByte(16)
      ..write(obj.minOrderAmount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
