// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cloud_backup_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CloudBackupSettingsAdapter extends TypeAdapter<CloudBackupSettings> {
  @override
  final int typeId = 5;

  @override
  CloudBackupSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CloudBackupSettings(
      cloudBackupEnabled: fields[0] as bool,
      lastBackupTime: fields[1] as DateTime?,
      userEmail: fields[2] as String?,
      userId: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CloudBackupSettings obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.cloudBackupEnabled)
      ..writeByte(1)
      ..write(obj.lastBackupTime)
      ..writeByte(2)
      ..write(obj.userEmail)
      ..writeByte(3)
      ..write(obj.userId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CloudBackupSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
