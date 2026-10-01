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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxHeight < 720;
            final isVeryCompact = constraints.maxHeight < 620;

            final logoSize = isVeryCompact ? 64.0 : (isCompact ? 80.0 : 110.0);
            final topSpacing = isVeryCompact ? 16.0 : (isCompact ? 24.0 : 48.0);
            final midSpacing = isVeryCompact ? 16.0 : (isCompact ? 24.0 : 40.0);
            final keySize = isVeryCompact ? 56.0 : (isCompact ? 64.0 : 76.0);
            final horizontalPadding = constraints.maxWidth < 360 ? 16.0 : 36.0;

            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      SizedBox(height: topSpacing),
                      // Logo / App name
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset('assets/images/logo.png',
                            width: logoSize, height: logoSize),
                      ),
                      const SizedBox(height: 12),
                      Text('Bhola Traders',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: isCompact ? 26 : 32,
                              fontWeight: FontWeight.bold)),
                      const Text('Trust • Quality • Growth',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 16)),

                      SizedBox(height: midSpacing),

                      // PIN dots
                      Text(
                        _error
                            ? '❌ गलत PIN / Wrong PIN'
                            : 'PIN डालें / Enter PIN',
                        style: TextStyle(
                          color: _error ? Colors.red[200] : Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                            4,
                            (i) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  width: 16,
                                  height: 16,
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
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      else
                        _NumPad(
                          onDigit: _onDigit,
                          onDelete: _onDelete,
                          keySize: keySize,
                          horizontalPadding: horizontalPadding,
                        ),

                      SizedBox(height: isCompact ? 16 : 32),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NumPad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onDelete;
  final double keySize;
  final double horizontalPadding;

  const _NumPad({
    required this.onDigit,
    required this.onDelete,
    this.keySize = 72,
    this.horizontalPadding = 40,
  });

  @override
  Widget build(BuildContext context) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: keys
            .map((row) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: row
                      .map((k) => _NumKey(
                            label: k,
                            size: keySize,
                            onTap: k == '⌫'
                                ? null
                                : k.isEmpty
                                    ? null
                                    : () => onDigit(k),
                            onDeleteTap: k == '⌫' ? onDelete : null,
                          ))
                      .toList(),
                ))
            .toList(),
      ),
    );
  }
}

class _NumKey extends StatelessWidget {
  final String label;
  final double size;
  final VoidCallback? onTap;
  final VoidCallback? onDeleteTap;

  const _NumKey({
    required this.label,
    this.size = 72,
    this.onTap,
    this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return SizedBox(width: size, height: size);

    return GestureDetector(
      onTap: onTap ?? onDeleteTap,
      child: Container(
        width: size,
        height: size,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.15),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
