import 'package:hive/hive.dart';

part 'cloud_backup_settings.g.dart';

@HiveType(typeId: 20)
class CloudBackupSettings extends HiveObject {
  @HiveField(0)
  bool cloudBackupEnabled;

  @HiveField(1)
  String? authToken; // Replaces googleAccessToken

  @HiveField(2)
  String? refreshToken; // For Supabase

  @HiveField(3)
  DateTime? lastBackupTime;

  @HiveField(4)
  String? userId; // Replaces googleEmail or stores uuid

  @HiveField(5)
  String? userEmail;

  CloudBackupSettings({
    this.cloudBackupEnabled = false,
    this.authToken,
    this.refreshToken,
    this.lastBackupTime,
    this.userId,
    this.userEmail,
  });
}
