// lib/core/widgets/voice_text_field.dart
import 'package:flutter/material.dart';
import '../../services/voice_service.dart';
import '../theme/app_theme.dart';

/// A TextFormField equipped with an inline speech-to-text microphone button.
/// Works offline in Hindi (hi_IN) with English fallback.
class VoiceTextFormField extends StatefulWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final String? prefixText;
  final TextStyle? prefixStyle;
  final Widget? extraSuffixIcon;
  final String? suffixText;
  final TextInputType? keyboardType;
  final TextStyle? style;
  final int maxLines;
  final int? minLines;
  final bool isNumeric;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool filled;
  final Color? fillColor;
  final bool autofocus;
  final bool enabled;
  final FocusNode? focusNode;

  const VoiceTextFormField({
    super.key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.prefixText,
    this.prefixStyle,
    this.extraSuffixIcon,
    this.suffixText,
    this.keyboardType,
    this.style,
    this.maxLines = 1,
    this.minLines,
    this.isNumeric = false,
    this.validator,
    this.onChanged,
    this.filled = false,
    this.fillColor,
    this.autofocus = false,
    this.enabled = true,
    this.focusNode,
  });

  @override
  State<VoiceTextFormField> createState() => _VoiceTextFormFieldState();
}

class _VoiceTextFormFieldState extends State<VoiceTextFormField>
    with SingleTickerProviderStateMixin {
  final VoiceService _voiceService = VoiceService();
  late AnimationController _animCtrl;

  static const _hindiNumberWords = <String, String>{
    'शून्य': '0', 'जीरो': '0',
    'एक': '1', 'दो': '2', 'तीन': '3', 'चार': '4', 'पांच': '5',
    'पाँच': '5', 'छह': '6', 'छः': '6', 'सात': '7', 'आठ': '8',
    'नौ': '9', 'दस': '10', 'ग्यारह': '11', 'बारह': '12',
    'तेरह': '13', 'चौदह': '14', 'पंद्रह': '15', 'सोलह': '16',
    'सत्रह': '17', 'अट्ठारह': '18', 'उन्नीस': '19', 'बीस': '20',
    'पच्चीस': '25', 'तीस': '30', 'पैंतीस': '35', 'चालीस': '40',
    'पैंतालीस': '45', 'पचास': '50', 'पचपन': '55', 'साठ': '60',
    'पैंसठ': '65', 'सत्तर': '70', 'पिचहत्तर': '75', 'अस्सी': '80',
    'पचासी': '85', 'नब्बे': '90', 'पंचानवे': '95', 'सौ': '100',
    'हजार': '1000', 'हज़ार': '1000', 'लाख': '100000',
    'ek': '1', 'do': '2', 'teen': '3', 'char': '4', 'paanch': '5',
    'panch': '5', 'cheh': '6', 'saat': '7', 'aath': '8', 'nau': '9',
    'das': '10', 'gyarah': '11', 'barah': '12', 'bees': '20',
    'sau': '100', 'hazar': '1000', 'lakh': '100000',
  };

  @override
  void initState() {
    super.initState();
    _voiceService.addListener(_onVoiceStateChanged);
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
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
    if (mounted) setState(() {});
  }

  String _cleanNumericInput(String raw) {
    // 1. Convert Devanagari numerals
    const devanagari = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
    var text = raw.toLowerCase().trim();
    for (int i = 0; i < devanagari.length; i++) {
      text = text.replaceAll(devanagari[i], '$i');
    }

    // 2. Convert Hindi word numbers
    for (final entry in _hindiNumberWords.entries) {
      text = text.replaceAll(entry.key, entry.value);
    }

    // 3. Extract first valid decimal/integer number
    final match = RegExp(r'\d+(\.\d+)?').firstMatch(text);
    if (match != null) {
      return match.group(0)!;
    }

    // 4. Fallback: filter only digits and decimal dot
    final cleaned = text.replaceAll(RegExp(r'[^0-9.]'), '');
    return cleaned;
  }

  void _toggleListening() {
    if (_voiceService.isListening) {
      _voiceService.stop();
    } else {
      _voiceService.startListening(
        onResult: (transcript) {
          if (transcript.isNotEmpty && mounted) {
            String processed = transcript;
            final isNum = widget.isNumeric ||
                widget.keyboardType == TextInputType.number ||
                widget.keyboardType == const TextInputType.numberWithOptions(decimal: true) ||
                widget.keyboardType == TextInputType.phone;

            if (isNum) {
              final numStr = _cleanNumericInput(transcript);
              if (numStr.isNotEmpty) {
                processed = numStr;
              }
            }

            if (widget.maxLines > 1 && widget.controller.text.isNotEmpty) {
              widget.controller.text = '${widget.controller.text} $processed';
            } else {
              widget.controller.text = processed;
            }

            // Move cursor to end
            widget.controller.selection = TextSelection.fromPosition(
              TextPosition(offset: widget.controller.text.length),
            );

            widget.onChanged?.call(widget.controller.text);
          }
        },
        onError: (err) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(err),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isListening = _voiceService.isListening;

    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      style: widget.style,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      validator: widget.validator,
      onChanged: widget.onChanged,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: isListening ? 'बोलिए... / Listening...' : widget.hintText,
        hintStyle: isListening
            ? const TextStyle(color: AppTheme.moneyOut, fontWeight: FontWeight.bold)
            : null,
        prefixIcon: widget.prefixIcon,
        prefixText: widget.prefixText,
        prefixStyle: widget.prefixStyle,
        filled: widget.filled,
        fillColor: widget.fillColor,
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (widget.suffixText != null)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  widget.suffixText!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (widget.extraSuffixIcon != null) widget.extraSuffixIcon!,
            Tooltip(
              message: isListening
                  ? 'सुन रहा है... (रोकने के लिए टैप करें)'
                  : 'बोलकर लिखें / Speak to type',
              child: InkWell(
                onTap: widget.enabled ? _toggleListening : null,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: AnimatedBuilder(
                    animation: _animCtrl,
                    builder: (context, child) {
                      final scale = isListening ? 1.0 + (_animCtrl.value * 0.25) : 1.0;
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isListening
                                ? AppTheme.moneyOut.withOpacity(0.18)
                                : AppTheme.primary.withOpacity(0.08),
                          ),
                          child: Icon(
                            isListening ? Icons.mic : Icons.mic_none_rounded,
                            size: 20,
                            color: isListening ? AppTheme.moneyOut : AppTheme.primary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}
