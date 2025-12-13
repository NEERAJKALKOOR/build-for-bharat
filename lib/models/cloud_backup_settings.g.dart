part of 'cloud_backup_settings.dart';

class CloudBackupSettingsAdapter extends TypeAdapter<CloudBackupSettings> {
  @override
  final int typeId = 20;

  @override
  CloudBackupSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CloudBackupSettings(
      cloudBackupEnabled: fields[0] as bool,
      authToken: fields[1] as String?,
      refreshToken: fields[2] as String?,
      lastBackupTime: fields[3] as DateTime?,
      userId: fields[4] as String?,
      userEmail: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CloudBackupSettings obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.cloudBackupEnabled)
      ..writeByte(1)
      ..write(obj.authToken)
      ..writeByte(2)
      ..write(obj.refreshToken)
      ..writeByte(3)
      ..write(obj.lastBackupTime)
      ..writeByte(4)
      ..write(obj.userId)
      ..writeByte(5)
      ..write(obj.userEmail);
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
