import 'package:hive/hive.dart';

part 'auth_model.g.dart';

@HiveType(typeId: 0)
class AuthModel extends HiveObject {
  @HiveField(0)
  String pinHash;

  @HiveField(1)
  String? securityQuestion;

  @HiveField(2)
  String? securityAnswerHash;

  AuthModel({
    required this.pinHash,
    this.securityQuestion,
    this.securityAnswerHash,
  });
}