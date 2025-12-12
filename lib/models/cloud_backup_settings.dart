import 'package:hive/hive.dart';

part 'cloud_backup_settings.g.dart';

@HiveType(typeId: 5)
class CloudBackupSettings extends HiveObject {
  @HiveField(0)
  bool cloudBackupEnabled;

  @HiveField(1)
  DateTime? lastBackupTime;

  @HiveField(2)
  String? userEmail;

  @HiveField(3)
  String? userId; // SHA256 hash of email

  CloudBackupSettings({
    this.cloudBackupEnabled = false,
    this.lastBackupTime,
    this.userEmail,
    this.userId,
  });

  String getLastBackupFormatted() {
    if (lastBackupTime == null) {
      return 'Never';
    }
    final now = DateTime.now();
    final diff = now.difference(lastBackupTime!);
    
    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} minutes ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours} hours ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${lastBackupTime!.day}/${lastBackupTime!.month}/${lastBackupTime!.year}';
    }
  }
}
