import 'package:hive/hive.dart';

@HiveType(typeId: 20)
class CloudBackupSettings extends HiveObject {
  @HiveField(0)
  bool cloudBackupEnabled;

  @HiveField(1)
  String? googleEmail;

  @HiveField(2)
  String? googleAccessToken;

  @HiveField(3)
  DateTime? lastBackupTime;

  @HiveField(4)
  String? driveFolderId;

  @HiveField(5)
  String? backupsFolderId;

  CloudBackupSettings({
    this.cloudBackupEnabled = false,
    this.googleEmail,
    this.googleAccessToken,
    this.lastBackupTime,
    this.driveFolderId,
    this.backupsFolderId,
  });
}

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
      googleEmail: fields[1] as String?,
      googleAccessToken: fields[2] as String?,
      lastBackupTime: fields[3] as DateTime?,
      driveFolderId: fields[4] as String?,
      backupsFolderId: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CloudBackupSettings obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.cloudBackupEnabled)
      ..writeByte(1)
      ..write(obj.googleEmail)
      ..writeByte(2)
      ..write(obj.googleAccessToken)
      ..writeByte(3)
      ..write(obj.lastBackupTime)
      ..writeByte(4)
      ..write(obj.driveFolderId)
      ..writeByte(5)
      ..write(obj.backupsFolderId);
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
