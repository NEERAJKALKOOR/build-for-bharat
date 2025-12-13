import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/session_manager.dart';
import 'email_login_screen.dart';
import 'export_import_screen.dart';
import '../theme/app_theme.dart';
import '../services/supabase_backup_service.dart';
import '../models/cloud_backup_settings.dart';
import '../models/user_session.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SupabaseBackupService _backupService = SupabaseBackupService();
  CloudBackupSettings? _backupSettings;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initBackupService();
  }

  Future<void> _initBackupService() async {
    await _backupService.init();
    
    // Check if user is already verified in app
    final session = await SessionManager().getCurrentSession();
    if (session != null && session.isValid) {
      _backupService.setUserEmail(session.email);
       // Auto-enable if session exists and not explicitly disabled? 
       // Or just let user toggle. We will update UI to show "Signed in as..."
    }
    
    _loadBackupSettings();
    _backupService.addListener(_loadBackupSettings);
  }

  @override
  void dispose() {
    _backupService.removeListener(_loadBackupSettings);
    super.dispose();
  }

  void _loadBackupSettings() {
    if (mounted) {
      setState(() => _backupSettings = _backupService.settings);
    }
  }

  Future<void> _toggleBackup(bool value) async {
    if (_backupSettings == null) return;
    
    // Access Session
    final session = await SessionManager().getCurrentSession();
    final String? userEmail = session?.email ?? _backupSettings?.userEmail;

    // If enabling, ensure we have an email (checked via Session usually)
    if (value && userEmail == null) {
       // Only show auth dialog if NO local session exists
       _showAuthDialog();
    } else {
       if (value && userEmail != null) {
          _backupService.setUserEmail(userEmail);
       }
       _backupSettings!.cloudBackupEnabled = value;
       await _backupSettings!.save();
       _loadBackupSettings();
    }
  }

  void _showAuthDialog() {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Connect Supabase'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
          ],
        ),
        actions: [
          TextButton(
             onPressed: () => Navigator.pop(ctx),
             child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                // Try sign in, if fails, try sign up
                try {
                  await _backupService.signIn(emailCtrl.text.trim(), passCtrl.text.trim());
                } catch (e) {
                   // If sign in fails, maybe account doesn't exist? Try sign up.
                   // Actually, safer to let user choose. But for quick integration:
                   await _backupService.signUp(emailCtrl.text.trim(), passCtrl.text.trim());
                }
              } catch (e) {
                _showError('Auth failed: ${e.toString()}');
              } finally {
                setState(() => _isLoading = false);
              }
            },
            child: const Text('CONNECT / LOGIN'),
          )
        ],
      ),
    );
  }

  Future<void> _handleSignOut() async {
    setState(() => _isLoading = true);
    await _backupService.signOut();
    setState(() => _isLoading = false);
  }

  Future<void> _handleBackupNow() async {
    if (_backupSettings?.cloudBackupEnabled != true) return;

    setState(() => _isLoading = true);
    try {
      await _backupService.backupNow();
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
      final files = await _backupService.listBackups();
      if (!mounted) return;

      if (files.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scanning... No backups found.')),
        );
        return;
      }

      // Show selection dialog
      final selected = await showDialog<FileObject>(
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
                final dateStr = DateFormat('MMM d, y HH:mm').format(DateTime.parse(file.createdAt!));
                // Size might not be directly available on FileObject in older versions, checking
                // Assuming standard FileObject
                final name = file.name;
                
                return ListTile(
                  leading: const Icon(Icons.description, color: AppTheme.primaryColor),
                  title: Text(dateStr),
                  subtitle: Text(name),
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
         setState(() => _isLoading = true);
         await _backupService.restoreBackup(selected.name);
         if (mounted) {
            _showSuccess('Restore completed successfully. Restart requires reloading app data.');
         }
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
    // Get effective email from service, fallback to settings
    final userEmail = _backupService.settings?.userId ?? _backupService.settings?.userEmail; 
    // Note: In our Logic, we use userId field or manualEmail. 
    // Let's rely on what the service reports as its 'effective' ID if possible, 
    // or deeper, check SessionManager directly for UI status.
    
    return FutureBuilder<UserSession?>(
      future: SessionManager().getCurrentSession(),
      builder: (context, snapshot) {
         final sessionEmail = snapshot.data?.email;
         final displayEmail = sessionEmail ?? userEmail;
         final bool isSignedOn = displayEmail != null;

         return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'CLOUD BACKUP (SUPABASE)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Enable Cloud Backup'),
              subtitle: Text(isSignedOn ? 'Backup as $displayEmail' : 'Backup your data to Supabase'),
              value: enabled,
              onChanged: _toggleBackup,
              activeColor: AppTheme.primaryColor,
            ),
            
            // Login button if not signed in via App logic
            if (!isSignedOn)
               Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.login),
                  label: const Text('Log in with Supabase'),
                  onPressed: _showAuthDialog,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                  ),
                ),
              ),

            if (enabled && isSignedOn) ...[
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
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     Text('Last Backup: $lastBackup', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                     // Hide Sign Out if it is an App Session
                     if (sessionEmail == null) 
                        TextButton(onPressed: _handleSignOut, child: const Text("Sign Out Cloud"))
                   ],
                 ),
               ),
            ],
          ],
        );
      }
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
