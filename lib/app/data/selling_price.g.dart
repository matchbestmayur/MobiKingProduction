// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selling_price.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SellingPriceAdapter extends TypeAdapter<SellingPrice> {
  @override
  final int typeId = 4;

  @override
  SellingPrice read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SellingPrice(
      id: fields[0] as String?,
      price: fields[1] as int,
      createdAt: fields[2] as DateTime?,
      updatedAt: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, SellingPrice obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.price)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SellingPriceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
