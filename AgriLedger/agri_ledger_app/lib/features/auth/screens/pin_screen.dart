// lib/features/auth/screens/pin_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/providers.dart';
import '../../home/screens/home_screen.dart';

class PinScreen extends ConsumerStatefulWidget {
  const PinScreen({super.key});

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  String _entered = '';
  bool _error = false;
  bool _loading = false;

  void _onDigit(String digit) {
    if (_entered.length >= 4) return;
    setState(() {
      _entered += digit;
      _error = false;
    });
    if (_entered.length == 4) _verify();
  }

  void _onDelete() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  Future<void> _verify() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString('user_pin') ?? '1234';

    await Future.delayed(const Duration(milliseconds: 300)); // feel of auth

    if (_entered == savedPin) {
      prefs.setString('user_pin', savedPin);
      ref.read(isAuthenticatedProvider.notifier).state = true;
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } else {
      setState(() {
        _error = true;
        _entered = '';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            // Logo / App name
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset('assets/images/logo.png', width: 120, height: 120),
            ),
            const SizedBox(height: 16),
            const Text('Bhola Traders',
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const Text('Trust • Quality • Growth',
              style: TextStyle(color: Colors.white70, fontSize: 18)),

            const SizedBox(height: 60),

            // PIN dots
            Text(
              _error ? '❌ गलत PIN / Wrong PIN' : 'PIN डालें / Enter PIN',
              style: TextStyle(
                color: _error ? Colors.red[200] : Colors.white70,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 20, height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _entered.length
                    ? Colors.white
                    : Colors.white30,
                ),
              )),
            ),

            const Spacer(),

            // Numpad
            if (_loading)
              const CircularProgressIndicator(color: Colors.white)
            else
              _NumPad(onDigit: _onDigit, onDelete: _onDelete),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _NumPad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onDelete;

  const _NumPad({required this.onDigit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final keys = [
      ['1','2','3'],
      ['4','5','6'],
      ['7','8','9'],
      ['','0','⌫'],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: keys.map((row) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: row.map((k) => _NumKey(
            label: k,
            onTap: k == '⌫'
              ? null
              : k.isEmpty ? null : () => onDigit(k),
            onDeleteTap: k == '⌫' ? onDelete : null,
          )).toList(),
        )).toList(),
      ),
    );
  }
}

class _NumKey extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onDeleteTap;

  const _NumKey({required this.label, this.onTap, this.onDeleteTap});

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox(width: 80, height: 80);

    return GestureDetector(
      onTap: onTap ?? onDeleteTap,
      child: Container(
        width: 80, height: 80,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.15),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white, fontSize: 26, fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
