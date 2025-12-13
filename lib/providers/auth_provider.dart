import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  bool _isAuthenticated = false;

  AuthProvider(this._authService);

  bool get isAuthenticated => _isAuthenticated;
  bool get isPinSet => _authService.isPinSet;

  Future<void> createPin(String pin,
      {String? securityQuestion, String? securityAnswer}) async {
    await _authService.createPin(
      pin,
      securityQuestion: securityQuestion,
      securityAnswer: securityAnswer,
    );
    _isAuthenticated = true;
    notifyListeners();
  }

  bool login(String pin) {
    _isAuthenticated = _authService.verifyPin(pin);
    notifyListeners();
    return _isAuthenticated;
  }

  void logout() {
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<void> changePin(String currentPin, String newPin) async {
    if (_authService.verifyPin(currentPin)) {
      await _authService.changePin(newPin);
    } else {
      throw Exception('Invalid current PIN');
    }
  }

  Future<void> resetPinWithSecurity(String answer, String newPin) async {
    if (_authService.verifySecurityAnswer(answer)) {
      await _authService.resetPin(newPin);
    } else {
      throw Exception('Invalid security answer');
    }
  }

  String? getSecurityQuestion() => _authService.getSecurityQuestion();
}
