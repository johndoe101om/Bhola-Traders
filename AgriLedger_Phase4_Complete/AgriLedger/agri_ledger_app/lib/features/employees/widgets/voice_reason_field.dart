// lib/features/employees/widgets/voice_reason_field.dart
import 'package:flutter/material.dart';
import '../../../services/voice_service.dart';
import '../../../core/theme/app_theme.dart';

class VoiceReasonField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final int maxLines;

  const VoiceReasonField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText = '',
    this.maxLines = 1,
  });

  @override
  State<VoiceReasonField> createState() => _VoiceReasonFieldState();
}

class _VoiceReasonFieldState extends State<VoiceReasonField>
    with SingleTickerProviderStateMixin {
  final VoiceService _voiceService = VoiceService();
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _voiceService.addListener(_onVoiceStateChanged);
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
  }

  @override
  void dispose() {
    _voiceService.removeListener(_onVoiceStateChanged);
    _voiceService.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _onVoiceStateChanged() {
    if (_voiceService.isListening) {
      if (!_animCtrl.isAnimating) _animCtrl.repeat(reverse: true);
    } else {
      _animCtrl.stop();
      _animCtrl.reset();
    }
    setState(() {});
  }

  void _toggleListening() {
    if (_voiceService.isListening) {
      _voiceService.stop();
    } else {
      _voiceService.startListening(
        onResult: (transcript) {
          if (transcript.isNotEmpty) {
            final current = widget.controller.text;
            widget.controller.text =
                current.isEmpty ? transcript : '$current $transcript';
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      maxLines: widget.maxLines,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: GestureDetector(
          onTap: _toggleListening,
          child: AnimatedBuilder(
            animation: _animCtrl,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_animCtrl.value * 0.2),
                child: Icon(
                  _voiceService.isListening ? Icons.mic : Icons.mic_none,
                  color: _voiceService.isListening
                      ? AppTheme.moneyOut
                      : AppTheme.primary,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
