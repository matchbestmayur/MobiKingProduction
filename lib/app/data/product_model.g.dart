// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductModelAdapter extends TypeAdapter<ProductModel> {
  @override
  final int typeId = 2;

  @override
  ProductModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductModel(
      id: fields[0] as String,
      name: fields[1] as String,
      fullName: fields[2] as String,
      slug: fields[3] as String,
      description: fields[4] as String,
      active: fields[5] as bool,
      newArrival: fields[6] as bool,
      liked: fields[7] as bool,
      bestSeller: fields[8] as bool,
      recommended: fields[9] as bool,
      sellingPrice: (fields[10] as List).cast<SellingPrice>(),
      categoryId: fields[11] as String,
      stockIds: (fields[12] as List).cast<String>(),
      orderIds: (fields[13] as List).cast<String>(),
      groupIds: (fields[14] as List).cast<String>(),
      totalStock: fields[15] as int,
      variants: (fields[16] as Map).cast<String, int>(),
      images: (fields[17] as List).cast<String>(),
      descriptionPoints: (fields[18] as List).cast<String>(),
      keyInformation: (fields[19] as List).cast<KeyInformation>(),
      regularPrice: fields[20] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, ProductModel obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.fullName)
      ..writeByte(3)
      ..write(obj.slug)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.active)
      ..writeByte(6)
      ..write(obj.newArrival)
      ..writeByte(7)
      ..write(obj.liked)
      ..writeByte(8)
      ..write(obj.bestSeller)
      ..writeByte(9)
      ..write(obj.recommended)
      ..writeByte(10)
      ..write(obj.sellingPrice)
      ..writeByte(11)
      ..write(obj.categoryId)
      ..writeByte(12)
      ..write(obj.stockIds)
      ..writeByte(13)
      ..write(obj.orderIds)
      ..writeByte(14)
      ..write(obj.groupIds)
      ..writeByte(15)
      ..write(obj.totalStock)
      ..writeByte(16)
      ..write(obj.variants)
      ..writeByte(17)
      ..write(obj.images)
      ..writeByte(18)
      ..write(obj.descriptionPoints)
      ..writeByte(19)
      ..write(obj.keyInformation)
      ..writeByte(20)
      ..write(obj.regularPrice);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
