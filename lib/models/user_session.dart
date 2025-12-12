import 'package:hive/hive.dart';

part 'user_session.g.dart';

@HiveType(typeId: 4)
class UserSession extends HiveObject {
  @HiveField(0)
  String email;

  @HiveField(1)
  String token;

  @HiveField(2)
  DateTime createdAt;

  @HiveField(3)
  DateTime expiresAt;

  @HiveField(4)
  bool isActive;

  UserSession({
    required this.email,
    required this.token,
    required this.createdAt,
    required this.expiresAt,
    this.isActive = true,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get isValid => isActive && !isExpired;
}
