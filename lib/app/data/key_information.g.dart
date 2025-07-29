// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'key_information.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class KeyInformationAdapter extends TypeAdapter<KeyInformation> {
  @override
  final int typeId = 3;

  @override
  KeyInformation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return KeyInformation(
      title: fields[0] as String,
      content: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, KeyInformation obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.content);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KeyInformationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
