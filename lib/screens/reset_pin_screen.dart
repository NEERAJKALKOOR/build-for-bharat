import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class ResetPinScreen extends StatefulWidget {
  const ResetPinScreen({Key? key}) : super(key: key);

  @override
  State<ResetPinScreen> createState() => _ResetPinScreenState();
}

class _ResetPinScreenState extends State<ResetPinScreen> {
  final _answerController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  @override
  void dispose() {
    _answerController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _resetPin() async {
    final answer = _answerController.text.trim();
    final newPin = _newPinController.text.trim();
    final confirm = _confirmPinController.text.trim();

    if (answer.isEmpty) {
      _showError('Please answer the security question');
      return;
    }

    if (newPin.isEmpty || newPin.length < 4) {
      _showError('PIN must be at least 4 digits');
      return;
    }

    if (newPin != confirm) {
      _showError('PINs do not match');
      return;
    }

    try {
      await context.read<AuthProvider>().resetPinWithSecurity(answer, newPin);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('PIN reset successfully'),
            backgroundColor: Colors.green),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      _showError('Invalid security answer');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = context.read<AuthProvider>().getSecurityQuestion();

    return Scaffold(
      appBar: AppBar(title: const Text('Reset PIN')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.help_outline, size: 80, color: Colors.orange),
            const SizedBox(height: 24),
            Text(
              question ?? 'Security Question',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _answerController,
              decoration: const InputDecoration(
                labelText: 'Your Answer',
                prefixIcon: Icon(Icons.check_circle_outline),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _newPinController,
              decoration: const InputDecoration(
                labelText: 'New PIN',
                prefixIcon: Icon(Icons.pin),
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPinController,
              decoration: const InputDecoration(
                labelText: 'Confirm New PIN',
                prefixIcon: Icon(Icons.pin),
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _resetPin,
              child: const Text('RESET PIN'),
            ),
          ],
        ),
      ),
    );
  }
}
