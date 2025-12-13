import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../models/otp_verification.dart';

class OtpService {
  static const String _otpBoxName = 'otpBox';

  // FREE SMTP Configuration - Users should replace with their own Gmail App Password
  // To get Gmail App Password: https://myaccount.google.com/apppasswords
  static const String _smtpUsername = '1ms23ad058@msrit.edu';
  static const String _smtpPassword =
      'zkaqyozdyssywapv'; // Remove spaces from App Password

  // For demo purposes, we'll use a mock mode that doesn't actually send emails
  static const bool _useMockMode =
      false; // Set to false to enable real email sending
  /// Generate a 6-digit OTP
  String _generateOtp() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  /// Send OTP to email address
  Future<bool> sendOtp(String email) async {
    try {
      final otp = _generateOtp();
      final box = await Hive.openBox<OtpVerification>(_otpBoxName);

      // Store OTP in Hive with 5-minute expiry
      final otpVerification = OtpVerification(
        email: email,
        otp: otp,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
        isUsed: false,
      );

      await box.put(email, otpVerification);

      if (_useMockMode) {
        // Mock mode: Print OTP to console for testing
        print('🔐 MOCK OTP for $email: $otp');
        print('⏰ Valid for 5 minutes');
        return true;
      } else {
        // Real SMTP mode: Send email via Gmail
        return await _sendEmailViaSMTP(email, otp);
      }
    } catch (e) {
      print('Error sending OTP: $e');
      return false;
    }
  }

  /// Send OTP email via Gmail SMTP (FREE)
  Future<bool> _sendEmailViaSMTP(String recipientEmail, String otp) async {
    try {
      // Configure Gmail SMTP (100% FREE)
      final smtpServer = gmail(_smtpUsername, _smtpPassword);

      // Create email message
      final message = Message()
        ..from = Address(_smtpUsername, 'Bharat Store')
        ..recipients.add(recipientEmail)
        ..subject = 'Your Bharat Store Login OTP'
        ..html = '''
          <div style="font-family: Arial, sans-serif; padding: 20px; background-color: #f5f5f5;">
            <div style="max-width: 600px; margin: 0 auto; background-color: white; border-radius: 10px; padding: 30px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
              <h2 style="color: #10B981; margin-bottom: 20px;">Bharat Store Login</h2>
              <p style="font-size: 16px; color: #333; margin-bottom: 20px;">Your One-Time Password (OTP) for login is:</p>
              <div style="background-color: #10B981; color: white; font-size: 32px; font-weight: bold; text-align: center; padding: 20px; border-radius: 8px; letter-spacing: 8px; margin-bottom: 20px;">
                $otp
              </div>
              <p style="font-size: 14px; color: #666; margin-bottom: 10px;">⏰ This OTP is valid for <strong>5 minutes</strong>.</p>
              <p style="font-size: 14px; color: #666; margin-bottom: 10px;">🔒 Do not share this OTP with anyone.</p>
              <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
              <p style="font-size: 12px; color: #999;">If you did not request this OTP, please ignore this email.</p>
            </div>
          </div>
        ''';

      // Send email
      await send(message, smtpServer);
      print('✅ OTP email sent to $recipientEmail');
      return true;
    } catch (e) {
      print('❌ Failed to send OTP email: $e');
      return false;
    }
  }

  /// Verify OTP
  Future<bool> verifyOtp(String email, String enteredOtp) async {
    try {
      final box = await Hive.openBox<OtpVerification>(_otpBoxName);
      final otpVerification = box.get(email);

      if (otpVerification == null) {
        print('❌ No OTP found for $email');
        return false;
      }

      if (!otpVerification.isValid) {
        print('❌ OTP expired or already used');
        return false;
      }

      if (otpVerification.otp != enteredOtp) {
        print('❌ Invalid OTP');
        return false;
      }

      // Mark OTP as used
      otpVerification.isUsed = true;
      await otpVerification.save();

      print('✅ OTP verified successfully for $email');
      return true;
    } catch (e) {
      print('Error verifying OTP: $e');
      return false;
    }
  }

  /// Get remaining OTP validity time
  Future<Duration?> getRemainingTime(String email) async {
    try {
      final box = await Hive.openBox<OtpVerification>(_otpBoxName);
      final otpVerification = box.get(email);

      if (otpVerification == null || otpVerification.isExpired) {
        return null;
      }

      return otpVerification.expiresAt.difference(DateTime.now());
    } catch (e) {
      return null;
    }
  }

  /// Clean up expired OTPs
  Future<void> cleanupExpiredOtps() async {
    try {
      final box = await Hive.openBox<OtpVerification>(_otpBoxName);
      final now = DateTime.now();

      final expiredKeys = box.values
          .where((otp) => otp.expiresAt.isBefore(now))
          .map((otp) => otp.email)
          .toList();

      for (final key in expiredKeys) {
        await box.delete(key);
      }

      print('🗑️ Cleaned up ${expiredKeys.length} expired OTPs');
    } catch (e) {
      print('Error cleaning up OTPs: $e');
    }
  }
}
