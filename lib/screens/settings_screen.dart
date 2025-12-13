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
    
    final session = await SessionManager().getCurrentSession();
    final String? userEmail = session?.email ?? _backupSettings?.userEmail;

    if (value && userEmail == null) {
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
            const SizedBox(height: 12),
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
                try {
                  await _backupService.signIn(emailCtrl.text.trim(), passCtrl.text.trim());
                } catch (e) {
                   await _backupService.signUp(emailCtrl.text.trim(), passCtrl.text.trim());
                }
              } catch (e) {
                _showError('Auth failed: ${e.toString()}');
              } finally {
                setState(() => _isLoading = false);
              }
            },
            child: const Text('CONNECT'),
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
        _showSuccess('✅ Backup successful');
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
        _showSuccess('No backups found');
        return;
      }

      final selected = await showModalBottomSheet<FileObject>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Restore from Backup', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: files.length,
                  itemBuilder: (ctx, i) {
                    final file = files[i];
                    final dateStr = DateFormat('MMM d, y • HH:mm').format(DateTime.parse(file.createdAt!));
                    
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.cloud_download, color: AppTheme.primaryColor, size: 20),
                      ),
                      title: Text(dateStr, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () => Navigator.pop(ctx, file),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );

      if (selected != null) {
         setState(() => _isLoading = true);
         await _backupService.restoreBackup(selected.name);
         if (mounted) {
            _showSuccess('Restore complete. Please restart app.');
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
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [const Icon(Icons.check_circle, color: Colors.white, size: 20), const SizedBox(width: 8), Text(message)]),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: Colors.black,
        title: const Text('Settings', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)) 
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Cloud Sync'),
                _buildCloudBackupCard(),
                
                const SizedBox(height: 24),
                _buildSectionHeader('Data Management'),
                _buildDataManagementCard(),

                const SizedBox(height: 24),
                _buildSectionHeader('Account'),
                _buildAccountCard(),

                const SizedBox(height: 24),
                _buildSectionHeader('App Info'),
                _buildAppInfoCard(),
                
                const SizedBox(height: 40),
                Center(
                  child: Text(
                    'BharatStore v1.0.0',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildCloudBackupCard() {
    final enabled = _backupSettings?.cloudBackupEnabled ?? false;
    final lastBackup = _backupSettings?.lastBackupTime != null 
       ? DateFormat('MMM d, HH:mm').format(_backupSettings!.lastBackupTime!)
       : 'Never';
    final userEmail = _backupService.settings?.userId ?? _backupService.settings?.userEmail; 
    
    return FutureBuilder<UserSession?>(
      future: SessionManager().getCurrentSession(),
      builder: (context, snapshot) {
         final sessionEmail = snapshot.data?.email;
         final displayEmail = sessionEmail ?? userEmail;
         final bool isSignedOn = displayEmail != null;

         return _buildCard(
           children: [
             SwitchListTile(
               contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
               activeColor: AppTheme.primaryColor,
               title: const Text('Cloud Backup', style: TextStyle(fontWeight: FontWeight.w600)),
               subtitle: Text(
                 isSignedOn ? 'Active • $displayEmail' : 'Disabled',
                 style: TextStyle(
                   color: isSignedOn ? AppTheme.primaryColor : Colors.grey,
                   fontSize: 13,
                 ),
               ),
               secondary: Container(
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(
                   color: enabled ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                   shape: BoxShape.circle,
                 ),
                 child: Icon(Icons.cloud_queue, color: enabled ? AppTheme.primaryColor : Colors.grey),
               ),
               value: enabled,
               onChanged: _toggleBackup,
             ),
             
             if (enabled && isSignedOn) ...[
               const Divider(height: 1, indent: 20, endIndent: 20),
               Padding(
                 padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                 child: Column(
                   children: [
                     Row(
                       children: [
                         Expanded(
                           child: _buildActionButton(
                             icon: Icons.upload_file_rounded,
                             label: 'Backup',
                             onTap: _handleBackupNow,
                             isPrimary: true,
                           ),
                         ),
                         const SizedBox(width: 12),
                         Expanded(
                           child: _buildActionButton(
                             icon: Icons.history_rounded,
                             label: 'Restore',
                             onTap: _handleRestore,
                             isPrimary: false,
                           ),
                         ),
                       ],
                     ),
                     const SizedBox(height: 12),
                     Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.access_time_rounded, size: 14, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text('Last synced: $lastBackup', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                      ],
                     ),
                   ],
                 ),
               ),
             ] else if (!isSignedOn) ...[
                const Divider(height: 1, indent: 20, endIndent: 20),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildActionButton(
                    icon: Icons.login_rounded,
                    label: 'Connect Account',
                    onTap: _showAuthDialog,
                    isPrimary: false,
                  ),
                ),
             ],
           ],
         );
      }
    );
  }

  Widget _buildDataManagementCard() {
    return _buildCard(
      children: [
        _buildListTile(
          icon: Icons.share_rounded,
          title: 'Export Data',
          subtitle: 'Share inventory & bills',
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ExportImportScreen()));
          },
        ),
      ],
    );
  }

  Widget _buildAccountCard() {
    return _buildCard(
      children: [
        _buildListTile(
          icon: Icons.logout_rounded,
          title: 'Sign Out',
          subtitle: 'End session on this device',
          iconColor: Colors.orange,
          onTap: () => _confirmLogout(context),
        ),
      ],
    );
  }

  Widget _buildAppInfoCard() {
    return _buildCard(
      children: [
        _buildListTile(
          icon: Icons.info_outline_rounded,
          title: 'About BharatStore',
          subtitle: 'Offline Inventory & Billing',
          showArrow: false,
        ),
        const Divider(height: 1, indent: 60),
        _buildListTile(
          icon: Icons.shield_outlined,
          title: 'Privacy & Storage',
          subtitle: 'Data stored locally + Cloud',
          showArrow: false,
        ),
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Color iconColor = AppTheme.primaryColor,
    bool showArrow = true,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[500])) : null,
      trailing: showArrow ? Icon(Icons.chevron_right_rounded, color: Colors.grey[300], size: 20) : null,
      onTap: onTap,
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isPrimary ? AppTheme.primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: isPrimary ? null : Border.all(color: Colors.grey[200]!, width: 1.5),
            boxShadow: isPrimary 
              ? [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
              : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isPrimary ? Colors.white : AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary ? Colors.white : AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out? You will need to login again.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          TextButton(
            onPressed: () async {
              final sessionManager = SessionManager();
              await sessionManager.invalidateSession();
              if (mounted) {
                Navigator.pop(ctx);
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
