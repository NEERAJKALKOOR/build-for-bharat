// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bill_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BillItemAdapter extends TypeAdapter<BillItem> {
  @override
  final int typeId = 2;

  @override
  BillItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BillItem(
      productId: fields[0] as String,
      name: fields[1] as String,
      price: fields[2] as double,
      quantity: fields[3] as int,
      unit: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, BillItem obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.productId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.price)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.unit);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BillItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
