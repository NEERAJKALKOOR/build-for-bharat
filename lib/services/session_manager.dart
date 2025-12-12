import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/user_session.dart';

class SessionManager {
  static const String _sessionBoxName = 'sessionBox';
  static const int _sessionValidityDays = 7;

  /// Create a new session for the user
  Future<UserSession> createSession(String email) async {
    try {
      final box = await Hive.openBox<UserSession>(_sessionBoxName);
      
      // Invalidate any existing sessions for this email
      await invalidateAllSessions();
      
      // Create new session
      final session = UserSession(
        email: email,
        token: const Uuid().v4(),
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(days: _sessionValidityDays)),
        isActive: true,
      );
      
      await box.put('current_session', session);
      print('✅ Session created for $email (expires in $_sessionValidityDays days)');
      
      return session;
    } catch (e) {
      print('Error creating session: $e');
      rethrow;
    }
  }

  /// Get current active session
  Future<UserSession?> getCurrentSession() async {
    try {
      final box = await Hive.openBox<UserSession>(_sessionBoxName);
      final session = box.get('current_session');
      
      if (session == null) {
        return null;
      }
      
      // Check if session is still valid
      if (!session.isValid) {
        print('⚠️ Session expired or inactive');
        await invalidateSession();
        return null;
      }
      
      return session;
    } catch (e) {
      print('Error getting current session: $e');
      return null;
    }
  }

  /// Check if user has valid session
  Future<bool> hasValidSession() async {
    final session = await getCurrentSession();
    return session != null && session.isValid;
  }

  /// Invalidate current session (logout)
  Future<void> invalidateSession() async {
    try {
      final box = await Hive.openBox<UserSession>(_sessionBoxName);
      final session = box.get('current_session');
      
      if (session != null) {
        session.isActive = false;
        await session.save();
        print('✅ Session invalidated for ${session.email}');
      }
    } catch (e) {
      print('Error invalidating session: $e');
    }
  }

  /// Invalidate all sessions
  Future<void> invalidateAllSessions() async {
    try {
      final box = await Hive.openBox<UserSession>(_sessionBoxName);
      
      for (final session in box.values) {
        session.isActive = false;
        await session.save();
      }
      
      print('✅ All sessions invalidated');
    } catch (e) {
      print('Error invalidating all sessions: $e');
    }
  }

  /// Extend current session
  Future<void> extendSession() async {
    try {
      final box = await Hive.openBox<UserSession>(_sessionBoxName);
      final session = box.get('current_session');
      
      if (session != null && session.isActive) {
        session.expiresAt = DateTime.now().add(Duration(days: _sessionValidityDays));
        await session.save();
        print('✅ Session extended for ${session.email}');
      }
    } catch (e) {
      print('Error extending session: $e');
    }
  }

  /// Get session expiry time
  Future<DateTime?> getSessionExpiry() async {
    final session = await getCurrentSession();
    return session?.expiresAt;
  }

  /// Get remaining session time
  Future<Duration?> getRemainingSessionTime() async {
    final session = await getCurrentSession();
    if (session == null) return null;
    
    return session.expiresAt.difference(DateTime.now());
  }

  /// Clear all session data (use with caution)
  Future<void> clearAllSessions() async {
    try {
      final box = await Hive.openBox<UserSession>(_sessionBoxName);
      await box.clear();
      print('🗑️ All session data cleared');
    } catch (e) {
      print('Error clearing sessions: $e');
    }
  }
}
