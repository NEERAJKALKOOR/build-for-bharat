import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'main_navigation_screen.dart';

class CreatePinScreen extends StatefulWidget {
  const CreatePinScreen({Key? key}) : super(key: key);

  @override
  State<CreatePinScreen> createState() => _CreatePinScreenState();
}

class _CreatePinScreenState extends State<CreatePinScreen> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  bool _obscurePin = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  void _createPin() async {
    final pin = _pinController.text.trim();
    final confirm = _confirmPinController.text.trim();
    final question = _questionController.text.trim();
    final answer = _answerController.text.trim();

    if (pin.isEmpty || pin.length < 4) {
      _showError('PIN must be at least 4 digits');
      return;
    }

    if (pin != confirm) {
      _showError('PINs do not match');
      return;
    }

    try {
      await context.read<AuthProvider>().createPin(
            pin,
            securityQuestion: question.isNotEmpty ? question : null,
            securityAnswer: answer.isNotEmpty ? answer : null,
          );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } catch (e) {
      _showError('Failed to create PIN');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create PIN'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: Colors.orange),
            const SizedBox(height: 24),
            const Text(
              'Secure Your Store',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a PIN to protect your data',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _pinController,
              decoration: InputDecoration(
                labelText: 'Enter PIN (4-6 digits)',
                prefixIcon: const Icon(Icons.pin),
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscurePin ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePin = !_obscurePin),
                ),
              ),
              keyboardType: TextInputType.number,
              obscureText: _obscurePin,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPinController,
              decoration: InputDecoration(
                labelText: 'Confirm PIN',
                prefixIcon: const Icon(Icons.pin),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              keyboardType: TextInputType.number,
              obscureText: _obscureConfirm,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Security Question (Optional)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _questionController,
              decoration: const InputDecoration(
                labelText: 'Security Question',
                hintText: 'e.g., Your first school name?',
                prefixIcon: Icon(Icons.help_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _answerController,
              decoration: const InputDecoration(
                labelText: 'Answer',
                prefixIcon: Icon(Icons.check_circle_outline),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _createPin,
              child: const Text('CREATE PIN'),
            ),
          ],
        ),
      ),
    );
  }
}
