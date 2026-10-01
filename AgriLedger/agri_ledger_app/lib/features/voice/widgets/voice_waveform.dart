// lib/features/voice/widgets/voice_waveform.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/voice_parser.dart';

/// Animated sound-wave bars shown while listening
class VoiceWaveform extends StatelessWidget {
  final Animation<double> animation;
  final int barCount;
  final Color color;

  const VoiceWaveform({
    super.key,
    required this.animation,
    this.barCount = 20,
    this.color = AppTheme.primaryLight,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(barCount, (i) {
            final phase = (i / barCount) * 2 * pi;
            final height =
                8 + 28 * ((sin(animation.value * 2 * pi + phase) + 1) / 2);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 50),
                width: 4,
                height: height,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.5 + 0.5 * (height / 36)),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────

// lib/features/voice/widgets/parsed_result_card.dart

/// Shows the raw voice text + confidence + what was extracted
class ParsedResultCard extends StatelessWidget {
  final ParsedVoiceEntry parsed;

  const ParsedResultCard({super.key, required this.parsed});

  @override
  Widget build(BuildContext context) {
    final confidence = parsed.confidence;
    final confidenceColor = confidence >= 0.7
        ? Colors.green[400]!
        : confidence >= 0.4
            ? Colors.orange[400]!
            : Colors.red[400]!;

    final confidenceLabel = confidence >= 0.7
        ? 'अच्छा / Good'
        : confidence >= 0.4
            ? 'ठीक है / OK'
            : 'अस्पष्ट / Unclear';

    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF1A1A2E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Raw transcript
          Row(
            children: [
              const Icon(Icons.record_voice_over_rounded,
                  color: Colors.white54, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '"${parsed.rawText}"',
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      height: 1.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Extracted fields as chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (parsed.partyName != null)
                _Chip('👤 ${parsed.partyName}', Colors.blue[700]!),
              if (parsed.txnType != null)
                _Chip(
                    _txnLabel(parsed.txnType!), _txnChipColor(parsed.txnType!)),
              if (parsed.commodity != null)
                _Chip(
                    '${_commodityEmoji(parsed.commodity!)} ${parsed.commodity}',
                    Colors.brown[600]!),
              if (parsed.quantityKg != null)
                _Chip('⚖️ ${parsed.quantityKg!.toStringAsFixed(1)} KG',
                    Colors.grey[700]!),
              if (parsed.ratePerKg != null)
                _Chip('₹ ${parsed.ratePerKg!.toStringAsFixed(0)}/KG',
                    Colors.grey[700]!),
              if (parsed.amount != null)
                _Chip('💰 ₹${parsed.amount!.toStringAsFixed(0)}',
                    Colors.green[700]!),
              if (parsed.bagCount != null)
                _Chip('📦 ${parsed.bagCount} बोरी', Colors.indigo[600]!),
              // Confidence
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: confidenceColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: confidenceColor, width: 1),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.auto_awesome_rounded,
                      color: confidenceColor, size: 14),
                  const SizedBox(width: 4),
                  Text('$confidenceLabel ${(confidence * 100).toInt()}%',
                      style: TextStyle(
                          color: confidenceColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _txnLabel(String type) => switch (type) {
        'purchase' => '⬇️ खरीदी',
        'sale' => '⬆️ बिक्री',
        'cash_in' => '➕ पैसा मिला',
        'cash_out' => '➖ पैसा दिया',
        'bag_given' => '📦 बोरी दी',
        'bag_returned' => '✅ बोरी वापस',
        _ => type,
      };

  Color _txnChipColor(String type) => switch (type) {
        'purchase' || 'cash_out' || 'bag_given' => Colors.red[700]!,
        _ => Colors.green[700]!,
      };

  String _commodityEmoji(String c) => switch (c) {
        'rice' => '🌾',
        'wheat' => '🌿',
        'maize' => '🌽',
        _ => '📦',
      };
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 13, fontWeight: FontWeight.w700)),
      );
}
