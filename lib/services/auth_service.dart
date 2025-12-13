import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import '../models/auth_model.dart';

class AuthService {
  static const String _boxName = 'auth';
  Box<AuthModel>? _box;

  Future<void> init() async {
    _box = await Hive.openBox<AuthModel>(_boxName);
  }

  String _hashString(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }

  bool get isPinSet => _box?.isNotEmpty ?? false;

  Future<void> createPin(String pin,
      {String? securityQuestion, String? securityAnswer}) async {
    final auth = AuthModel(
      pinHash: _hashString(pin),
      securityQuestion: securityQuestion,
      securityAnswerHash:
          securityAnswer != null ? _hashString(securityAnswer) : null,
    );
    await _box?.put('auth', auth);
  }

  bool verifyPin(String pin) {
    final auth = _box?.get('auth');
    if (auth == null) return false;
    return auth.pinHash == _hashString(pin);
  }

  bool verifySecurityAnswer(String answer) {
    final auth = _box?.get('auth');
    if (auth?.securityAnswerHash == null) return false;
    return auth!.securityAnswerHash == _hashString(answer);
  }

  String? getSecurityQuestion() {
    return _box?.get('auth')?.securityQuestion;
  }

  Future<void> changePin(String newPin) async {
    final auth = _box?.get('auth');
    if (auth != null) {
      auth.pinHash = _hashString(newPin);
      await auth.save();
    }
  }

  Future<void> resetPin(String newPin) async {
    await changePin(newPin);
  }

  Future<void> logout() async {
    // Just a marker for UI flow
  }
}
