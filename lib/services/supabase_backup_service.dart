import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/cloud_backup_settings.dart';
import '../utils/backup_json_builder.dart';
import '../utils/backup_json_reader.dart';
import 'package:hive/hive.dart';

class SupabaseBackupService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  final BackupJsonBuilder _jsonBuilder = BackupJsonBuilder();
  final BackupJsonReader _jsonReader = BackupJsonReader();

  static const String _bucketName = 'backups';

  CloudBackupSettings? _settings;
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  CloudBackupSettings? get settings => _settings;

  Future<void> init() async {
    final box = await Hive.openBox<CloudBackupSettings>('cloudBackupSettings');
    if (box.isNotEmpty) {
      _settings = box.getAt(0);
    } else {
      _settings = CloudBackupSettings();
      await box.add(_settings!);
    }
    notifyListeners();
  }

  // --- Auth & Setup ---

  Future<void> signIn(String email, String password) async {
    _setLoading(true);
    try {
      final AuthResponse res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.session != null) {
        _settings?.userEmail = res.user?.email;
        _settings?.userId = res.user?.id;
        _settings?.authToken = res.session?.accessToken;
        _settings?.refreshToken = res.session?.refreshToken;
        _settings?.cloudBackupEnabled = true; // Auto enable on login
        await _settings?.save();
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signUp(String email, String password) async {
    _setLoading(true);
    try {
      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      if (res.session != null) {
        _settings?.userEmail = res.user?.email;
        _settings?.userId = res.user?.id;
        _settings?.authToken = res.session?.accessToken;
        _settings?.refreshToken = res.session?.refreshToken;
        _settings?.cloudBackupEnabled = true;
        await _settings?.save();
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _supabase.auth.signOut();
      _settings?.cloudBackupEnabled = false;
      _settings?.authToken = null;
      _settings?.refreshToken = null;
      await _settings?.save();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print("SignOut error: $e");
    } finally {
      _setLoading(false);
    }
  }

  // --- Backup Logic ---

  // --- Custom Identity ---
  String? _manualUserEmail;

  void setUserEmail(String? email) {
    if (_manualUserEmail != email) {
      _manualUserEmail = email;
      // If we have a manual email, ensure we consider it enabled if desired,
      // but strictly we should just use it for paths.
      // We won't auto-save settings here to avoid side effects.
      notifyListeners();
    }
  }

  String get _effectiveUserId {
    // Prefer Supabase Auth ID if available, else manual email, else fallback
    return _supabase.auth.currentUser?.id ??
        _manualUserEmail ??
        _settings?.userId ??
        'unknown_user';
  }

  // --- Backup Logic ---

  Future<void> backupNow() async {
    // Allow backup if cloud enabled OR if we have a manual email (meaning we want to backup)
    if (!(_settings?.cloudBackupEnabled ?? false) && _manualUserEmail == null)
      return;
    _setLoading(true);

    try {
      final String jsonString = await _jsonBuilder.buildBackupJson();
      final Directory tempDir = await getTemporaryDirectory();
      final File tempFile = File('${tempDir.path}/backup_temp.json');
      await tempFile.writeAsString(jsonString);

      final String fileName = 'backup_${DateTime.now().toIso8601String()}.json';
      final String userId = _effectiveUserId;
      final String filePath = '$userId/$fileName';

      await _supabase.storage.from(_bucketName).upload(
            filePath,
            tempFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      _settings?.lastBackupTime = DateTime.now();
      _settings?.userId = userId; // Persist used ID
      await _settings?.save();

      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // --- Restore Logic ---

  Future<List<FileObject>> listBackups() async {
    try {
      final String userId = _effectiveUserId;
      final List<FileObject> objects =
          await _supabase.storage.from(_bucketName).list(path: userId);
      // Sort by created_at desc
      objects.sort((a, b) =>
          DateTime.parse(b.createdAt!).compareTo(DateTime.parse(a.createdAt!)));
      return objects;
    } catch (e) {
      return [];
    }
  }

  Future<void> restoreBackup(String fileName) async {
    _setLoading(true);
    try {
      final String userId = _effectiveUserId;
      final String filePath = '$userId/$fileName';

      // Download file
      final Uint8List fileBytes =
          await _supabase.storage.from(_bucketName).download(filePath);
      final String jsonString = String.fromCharCodes(fileBytes);

      await _jsonReader.restoreFromJson(jsonString);
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
