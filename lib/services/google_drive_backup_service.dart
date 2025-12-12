import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../models/cloud_backup_settings.dart';
import '../utils/backup_json_builder.dart';
import '../utils/backup_json_reader.dart';

/// Google Drive backup service for manual backup/restore
class GoogleDriveBackupService {
  static const String _cloudBackupBoxName = 'cloudBackupSettingsBox';
  static const String _mainFolderName = 'BharatStore';
  static const String _backupsFolderName = 'Backups';
  
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveFileScope,
    ],
  );

  final BackupJsonBuilder _jsonBuilder = BackupJsonBuilder();
  final BackupJsonReader _jsonReader = BackupJsonReader();

  /// Get or create cloud backup settings
  Future<CloudBackupSettings> getSettings() async {
    // Ensure adapter is registered before this runs (in main.dart)
    if (!Hive.isBoxOpen(_cloudBackupBoxName)) {
      await Hive.openBox<CloudBackupSettings>(_cloudBackupBoxName);
    }
    final box = Hive.box<CloudBackupSettings>(_cloudBackupBoxName);
    
    if (box.isEmpty) {
      final settings = CloudBackupSettings();
      await box.put('settings', settings);
      return settings;
    }
    
    return box.get('settings') ?? CloudBackupSettings();
  }

  /// Save cloud backup settings
  Future<void> saveSettings(CloudBackupSettings settings) async {
    final box = Hive.box<CloudBackupSettings>(_cloudBackupBoxName);
    await box.put('settings', settings);
  }

  /// Sign in with Google and save credentials
  Future<void> signInWithGoogle() async {
    print('🔐 Starting Google Sign-In...');
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) throw Exception('Sign-in cancelled by user');

      print('✅ Signed in as: ${account.email}');
      final authentication = await account.authentication;
      final accessToken = authentication.accessToken;
      if (accessToken == null) throw Exception('Failed to get access token');

      final settings = await getSettings();
      settings.cloudBackupEnabled = true; // Enable on sign in
      settings.googleEmail = account.email;
      settings.googleAccessToken = accessToken;
      await settings.save(); // Using HiveObject save

      print('✅ Credentials saved');
    } catch (e) {
      print('❌ Sign-in error: $e');
      rethrow;
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    print('🔓 Signing out from Google...');
    try {
      await _googleSignIn.signOut();
      
      final settings = await getSettings();
      settings.cloudBackupEnabled = false;
      settings.googleEmail = null;
      settings.googleAccessToken = null;
      settings.driveFolderId = null;
      settings.backupsFolderId = null;
      await settings.save();
      
      print('✅ Signed out successfully');
    } catch (e) {
      print('❌ Sign-out error: $e');
      rethrow;
    }
  }

  /// Get authenticated Drive API client
  Future<drive.DriveApi> _getDriveApi() async {
    final settings = await getSettings();
    if (settings.googleAccessToken == null) {
      throw Exception('Not signed in. Please sign in with Google first.');
    }

    // Check if we have a silent sign-in available to refresh token if needed
    // This handles the "If token expired -> reauthenticate" requirement implicitly 
    // by ensuring we try to get a fresh token if possible.
    // However, google_sign_in handles this mostly. if the stored token is old, 
    // we might want to refresh it.
    if (_googleSignIn.currentUser != null) {
        final auth = await _googleSignIn.currentUser!.authentication;
        if (auth.accessToken != null && auth.accessToken != settings.googleAccessToken) {
            settings.googleAccessToken = auth.accessToken;
            await settings.save();
        }
    }

    final authClient = _GoogleAuthClient(settings.googleAccessToken!);
    return drive.DriveApi(authClient);
  }

  /// Ensure BharatStore/Backups folder structure exists
  Future<void> _ensureFolderStructure() async {
    print('📁 Ensuring folder structure...');
    final settings = await getSettings();
    final driveApi = await _getDriveApi();

    if (settings.driveFolderId != null && settings.backupsFolderId != null) {
      return;
    }

    try {
      // 1. Check/Create Main Folder
      String? mainFolderId = settings.driveFolderId;
      if (mainFolderId == null) {
        final q = "name='$_mainFolderName' and mimeType='application/vnd.google-apps.folder' and trashed=false";
        final list = await driveApi.files.list(q: q, spaces: 'drive');
        
        if (list.files?.isNotEmpty == true) {
          mainFolderId = list.files!.first.id!;
        } else {
          final folder = drive.File()
            ..name = _mainFolderName
            ..mimeType = 'application/vnd.google-apps.folder';
          final created = await driveApi.files.create(folder);
          mainFolderId = created.id!;
        }
        settings.driveFolderId = mainFolderId;
        await settings.save();
      }

      // 2. Check/Create Backups Folder
      String? backupsFolderId = settings.backupsFolderId;
      if (backupsFolderId == null) {
        final q = "name='$_backupsFolderName' and '$mainFolderId' in parents and mimeType='application/vnd.google-apps.folder' and trashed=false";
        final list = await driveApi.files.list(q: q, spaces: 'drive');

        if (list.files?.isNotEmpty == true) {
          backupsFolderId = list.files!.first.id!;
        } else {
          final folder = drive.File()
            ..name = _backupsFolderName
            ..parents = [mainFolderId!]
            ..mimeType = 'application/vnd.google-apps.folder';
          final created = await driveApi.files.create(folder);
          backupsFolderId = created.id!;
        }
        settings.backupsFolderId = backupsFolderId;
        await settings.save();
      }
    } catch (e) {
      print('❌ Folder creation error: $e');
      rethrow;
    }
  }

  /// Backup Now
  Future<void> backupNow() async {
    print('🚀 Starting manual backup...');
    final settings = await getSettings();
    if (!settings.cloudBackupEnabled) throw Exception('Cloud backup is not enabled');

    try {
      await _ensureFolderStructure();
      final driveApi = await _getDriveApi();

      // Build JSON
      final jsonString = await _jsonBuilder.buildBackupJson();
      
      // Save temp
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/bharatstore-backup.json');
      await file.writeAsString(jsonString);

      // Upload
      final fileName = 'backup-${DateTime.now().toIso8601String().replaceAll(':', '-')}.json';
      final driveFile = drive.File()
        ..name = fileName
        ..parents = [settings.backupsFolderId!]
        ..mimeType = 'application/json';
      
      final media = drive.Media(file.openRead(), file.lengthSync());
      await driveApi.files.create(driveFile, uploadMedia: media);

      // Update timestamp
      settings.lastBackupTime = DateTime.now();
      await settings.save();

      // Cleanup
      if (await file.exists()) await file.delete();
      print('✅ Backup successful');
    } catch (e) {
      print('❌ Backup failed: $e');
      rethrow;
    }
  }

  /// List Backups
  Future<List<DriveBackupFile>> listBackupFiles() async {
    try {
      await _ensureFolderStructure();
      final settings = await getSettings();
      final driveApi = await _getDriveApi();
      
      final q = "'${settings.backupsFolderId}' in parents and trashed=false";
      final list = await driveApi.files.list(
        q: q, 
        orderBy: 'createdTime desc',
        $fields: 'files(id, name, createdTime, size)',
      );

      return list.files?.map((f) => DriveBackupFile(
        id: f.id!,
        name: f.name!,
        createdTime: f.createdTime,
        size: int.tryParse(f.size ?? '0') ?? 0,
      )).toList() ?? [];
    } catch (e) {
      print('❌ List error: $e');
      rethrow;
    }
  }

  /// Restore Backup
  Future<void> restoreBackup(String fileId) async {
    print('🚀 Starting manual restore...');
    try {
      final driveApi = await _getDriveApi();
      
      // Download
      final media = await driveApi.files.get(fileId, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/bharatstore-restore.json');
      final sink = file.openWrite();
      await media.stream.pipe(sink);
      await sink.close();

      // Parse and Restore
      final jsonString = await file.readAsString();
      await _jsonReader.restoreFromJson(jsonString);

      // Cleanup
      if (await file.exists()) await file.delete();
      print('✅ Restore successful');
    } catch (e) {
      print('❌ Restore failed: $e');
      rethrow;
    }
  }
}

class DriveBackupFile {
  final String id;
  final String name;
  final DateTime? createdTime;
  final int size;

  DriveBackupFile({required this.id, required this.name, this.createdTime, required this.size});
}

class _GoogleAuthClient extends http.BaseClient {
  final String _accessToken;
  final http.Client _client = http.Client();
  _GoogleAuthClient(this._accessToken);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    return _client.send(request);
  }
}
