// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bill_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BillModelAdapter extends TypeAdapter<BillModel> {
  @override
  final int typeId = 2;

  @override
  BillModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BillModel(
      id: fields[0] as String,
      billType: fields[1] as String,
      customBillName: fields[2] as String?,
      amount: fields[3] as double,
      dueDate: fields[4] as DateTime,
      reminderDaysBefore: fields[5] as int,
      createdAt: fields[6] as DateTime,
      billImageUrl: fields[7] as String?,
      dueDateAutoDetected: fields[8] as bool,
      amountAutoDetected: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, BillModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.billType)
      ..writeByte(2)
      ..write(obj.customBillName)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.dueDate)
      ..writeByte(5)
      ..write(obj.reminderDaysBefore)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.billImageUrl)
      ..writeByte(8)
      ..write(obj.dueDateAutoDetected)
      ..writeByte(9)
      ..write(obj.amountAutoDetected);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BillModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
