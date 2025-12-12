import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/session_manager.dart';
import 'email_login_screen.dart';
import 'export_import_screen.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
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
              'Security',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.lock, color: Colors.blue),
            title: const Text('Change PIN'),
            subtitle: const Text('Update your security PIN'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showChangePinDialog(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.orange),
            title: const Text('Sign Out'),
            subtitle: const Text('Lock the app'),
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

  void _showChangePinDialog(BuildContext context) {
    final currentPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmPinController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPinController,
              decoration: const InputDecoration(
                labelText: 'Current PIN',
                prefixIcon: Icon(Icons.lock_open),
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: newPinController,
              decoration: const InputDecoration(
                labelText: 'New PIN',
                prefixIcon: Icon(Icons.lock),
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmPinController,
              decoration: const InputDecoration(
                labelText: 'Confirm New PIN',
                prefixIcon: Icon(Icons.lock),
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              final currentPin = currentPinController.text.trim();
              final newPin = newPinController.text.trim();
              final confirmPin = confirmPinController.text.trim();

              if (currentPin.isEmpty || newPin.isEmpty || confirmPin.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please fill all fields'),
                      backgroundColor: Colors.red),
                );
                return;
              }

              if (newPin.length < 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('PIN must be at least 4 digits'),
                      backgroundColor: Colors.red),
                );
                return;
              }

              if (newPin != confirmPin) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('New PINs do not match'),
                      backgroundColor: Colors.red),
                );
                return;
              }

              try {
                await context
                    .read<AuthProvider>()
                    .changePin(currentPin, newPin);
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('PIN changed successfully'),
                      backgroundColor: Colors.green),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Invalid current PIN'),
                      backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('CHANGE'),
          ),
        ],
      ),
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

              // Logout from PIN (existing)
              context.read<AuthProvider>().logout();

              Navigator.of(dialogContext).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const EmailLoginScreen()),
                (route) => false,
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('SIGN OUT'),
          ),
        ],
      ),
    );
  }
}
