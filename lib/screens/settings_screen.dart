import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/session_manager.dart';
import 'email_login_screen.dart';
import 'export_import_screen.dart';
import '../theme/app_theme.dart';
import '../services/google_drive_backup_service.dart';
import '../models/cloud_backup_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final GoogleDriveBackupService _backupService = GoogleDriveBackupService();
  CloudBackupSettings? _backupSettings;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBackupSettings();
  }

  Future<void> _loadBackupSettings() async {
    final settings = await _backupService.getSettings();
    if (mounted) {
      setState(() => _backupSettings = settings);
    }
  }

  Future<void> _toggleBackup(bool value) async {
    if (_backupSettings == null) return;
    
    setState(() => _isLoading = true);
    try {
      if (value) {
        // Turning ON: Requires Sign In
        if (_backupSettings!.googleEmail == null) {
          await _backupService.signInWithGoogle();
        } else {
           // enable locally if already signed in
           _backupSettings!.cloudBackupEnabled = true;
           await _backupService.saveSettings(_backupSettings!);
        }
      } else {
        // Turning OFF
        _backupSettings!.cloudBackupEnabled = false;
        await _backupService.saveSettings(_backupSettings!);
      }
      await _loadBackupSettings();
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await _backupService.signInWithGoogle();
      await _loadBackupSettings();
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleBackupNow() async {
    if (_backupSettings?.cloudBackupEnabled != true) return;

    setState(() => _isLoading = true);
    try {
      await _backupService.backupNow();
      await _loadBackupSettings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Backup successful')),
        );
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRestore() async {
    if (_backupSettings?.cloudBackupEnabled != true) return;

    setState(() => _isLoading = true);
    try {
      final files = await _backupService.listBackupFiles();
      if (!mounted) return;

      if (files.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scanning... No backups found.')),
        );
        return;
      }

      // Show selection dialog
      final selected = await showDialog<DriveBackupFile>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Restore from Backup'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: files.length,
              itemBuilder: (ctx, i) {
                final file = files[i];
                final dateStr = file.createdTime != null 
                  ? DateFormat('MMM d, y HH:mm').format(file.createdTime!) 
                  : 'Unknown Date';
                final sizeStr = '${(file.size / 1024).toStringAsFixed(1)} KB';
                
                return ListTile(
                  leading: const Icon(Icons.description, color: AppTheme.primaryColor),
                  title: Text(dateStr),
                  subtitle: Text(sizeStr),
                  onTap: () => Navigator.pop(ctx, file),
                );
              },
            ),
          ),
          actions: [
             TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ],
        ),
      );

      if (selected != null) {
         setState(() => _isLoading = true); // show loading again
         await _backupService.restoreBackup(selected.id);
         if (mounted) {
            _showSuccess('Restore completed successfully. Restarting app is recommended.');
         }
         await _loadBackupSettings();
      }

    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $message'), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : ListView(
        children: [
          _buildCloudBackupSection(),
          const Divider(),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Data Management',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.share, color: AppTheme.primaryColor),
            title: const Text('Share & Export'),
            subtitle: const Text('Export inventory and bills data'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ExportImportScreen()),
              );
            },
          ),
          const Divider(),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Account',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.orange),
            title: const Text('Sign Out'),
            subtitle: const Text('End your session'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _confirmLogout(context),
          ),
          const Divider(),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'About',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('BharatStore'),
            subtitle:
                Text('Version 1.0.0\nOffline Inventory, Billing & Analytics'),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.storage),
            title: Text('Storage'),
            subtitle: Text('All data stored locally on device using Hive'),
          ),
          const ListTile(
            leading: Icon(Icons.cloud_off),
            title: Text('Offline First'),
            subtitle: Text('No cloud, no servers, zero maintenance cost'),
          ),
        ],
      ),
    );
  }

  Widget _buildCloudBackupSection() {
    final enabled = _backupSettings?.cloudBackupEnabled ?? false;
    final lastBackup = _backupSettings?.lastBackupTime != null 
       ? DateFormat('MMM d, HH:mm').format(_backupSettings!.lastBackupTime!)
       : 'Never';
    final userEmail = _backupSettings?.googleEmail;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'CLOUD BACKUP (PRO FEATURE)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Enable Cloud Backup'),
          subtitle: Text(userEmail != null ? 'Signed in as $userEmail' : 'Backup your data to Google Drive'),
          value: enabled,
          onChanged: _toggleBackup,
          activeColor: AppTheme.primaryColor,
        ),
        if (!enabled)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Sign in with Google'),
              onPressed: _handleSignIn,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
              ),
            ),
          ),
        if (enabled) ...[
           Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
               children: [
                 Expanded(
                   child: ElevatedButton.icon(
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('Backup Now'),
                      onPressed: _handleBackupNow,
                      style: ElevatedButton.styleFrom(
                         backgroundColor: AppTheme.primaryColor,
                         foregroundColor: Colors.white,
                      ),
                   ),
                 ),
                 const SizedBox(width: 12),
                 Expanded(
                   child: OutlinedButton.icon(
                      icon: const Icon(Icons.cloud_download),
                      label: const Text('Restore'),
                      onPressed: _handleRestore,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                      ),
                   ),
                 ),
               ],
            ),
           ),
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
             child: Text('Last Backup: $lastBackup', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
           ),
        ],
      ],
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
            'Are you sure you want to sign out?\n\nThis will end your email session and you will need to login again with OTP.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              // Deactivate email session
              final sessionManager = SessionManager();
              await sessionManager.invalidateSession();

              if (mounted) {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const EmailLoginScreen()),
                  (route) => false,
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('SIGN OUT'),
          ),
        ],
      ),
    );
  }
}
