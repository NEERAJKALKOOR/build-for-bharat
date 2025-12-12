import 'package:hive/hive.dart';

part 'otp_verification.g.dart';

@HiveType(typeId: 5)
class OtpVerification extends HiveObject {
  @HiveField(0)
  String email;

  @HiveField(1)
  String otp;

  @HiveField(2)
  DateTime createdAt;

  @HiveField(3)
  DateTime expiresAt;

  @HiveField(4)
  bool isUsed;

  OtpVerification({
    required this.email,
    required this.otp,
    required this.createdAt,
    required this.expiresAt,
    this.isUsed = false,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get isValid => !isUsed && !isExpired;
}
