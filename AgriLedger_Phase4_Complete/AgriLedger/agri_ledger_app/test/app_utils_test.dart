import 'package:flutter_test/flutter_test.dart';
import 'package:agri_ledger_app/core/utils/app_utils.dart';
import 'package:agri_ledger_app/core/theme/app_theme.dart';

void main() {
  group('AppUtils formatting and helper tests', () {
    test('formats rupees with Indian currency symbol', () {
      final formatted = formatRupees(5000);
      expect(formatted, contains('5,000'));
      expect(formatted, contains('₹'));
    });

    test('formats kilograms correctly', () {
      expect(formatKg(250), equals('250 kg'));
      expect(formatKg(100.5), equals('100.5 kg'));
    });

    test('returns correct colors for transaction types', () {
      expect(txnColor('purchase'), equals(AppTheme.moneyOut));
      expect(txnColor('cash_out'), equals(AppTheme.moneyOut));
      expect(txnColor('sale'), equals(AppTheme.moneyIn));
      expect(txnColor('cash_in'), equals(AppTheme.moneyIn));
    });

    test('returns correct colors for direction', () {
      expect(directionColor('in'), equals(AppTheme.moneyIn));
      expect(directionColor('out'), equals(AppTheme.moneyOut));
    });

    test('safely parses ISO DateTime strings', () {
      final valid = tryParseDateTime('2026-05-01T10:30:00Z');
      expect(valid, isNotNull);
      expect(valid!.year, equals(2026));

      expect(tryParseDateTime(null), isNull);
      expect(tryParseDateTime(''), isNull);
      expect(tryParseDateTime('not-a-date'), isNull);
    });
  });
}
