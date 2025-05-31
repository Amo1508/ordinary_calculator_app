// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calculation_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CalculationRecordAdapter extends TypeAdapter<CalculationRecord> {
  @override
  final int typeId = 0;

  @override
  CalculationRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CalculationRecord()
      ..id = fields[0] as int?
      ..expression = fields[1] as String
      ..result = fields[2] as String
      ..createdAt = fields[3] as DateTime;
  }

  @override
  void write(BinaryWriter writer, CalculationRecord obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.expression)
      ..writeByte(2)
      ..write(obj.result)
      ..writeByte(3)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalculationRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
