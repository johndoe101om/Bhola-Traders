import 'package:flutter_test/flutter_test.dart';
import 'package:agri_ledger_app/services/voice_parser.dart';

void main() {
  group('VoiceParser Hindi & English NLP tests', () {
    test('parses Hindi purchase phrase with commodity, quantity, and rate', () {
      const input = 'राम लाल से 200 किलो धान 22 रुपये खरीदा';
      final result = VoiceParser.parse(input);

      expect(result.partyName, isNotNull);
      expect(result.partyName, contains('राम'));
      expect(result.commodity, equals('rice'));
      expect(result.quantityKg, equals(200.0));
      expect(result.ratePerKg, equals(22.0));
      expect(result.txnType, equals('purchase'));
    });

    test('parses Hindi cash out transaction', () {
      const input = 'श्याम को 500 रुपये दिए';
      final result = VoiceParser.parse(input);

      expect(result.partyName, isNotNull);
      expect(result.partyName, contains('श्याम'));
      expect(result.amount, equals(500.0));
      expect(result.txnType, equals('cash_out'));
    });

    test('parses Hindi cash in transaction', () {
      const input = 'मोहन से 1000 रुपये मिले';
      final result = VoiceParser.parse(input);

      expect(result.partyName, isNotNull);
      expect(result.partyName, contains('मोहन'));
      expect(result.amount, equals(1000.0));
      expect(result.txnType, equals('cash_in'));
    });

    test('parses bag given movement in Hindi', () {
      const input = 'सोहन को 10 बोरी दी';
      final result = VoiceParser.parse(input);

      expect(result.partyName, isNotNull);
      expect(result.partyName, contains('सोहन'));
      expect(result.bagCount, equals(10));
      expect(result.txnType, equals('bag_given'));
    });

    test('parses bag returned movement in Hindi', () {
      const input = 'रोहन ने 5 बोरी वापस दी';
      final result = VoiceParser.parse(input);

      expect(result.partyName, isNotNull);
      expect(result.partyName, contains('रोहन'));
      expect(result.bagCount, equals(5));
      expect(result.txnType, equals('bag_returned'));
    });

    test('parses English purchase phrase', () {
      const input = 'Purchase 150 kg wheat at 28 from Suresh';
      final result = VoiceParser.parse(input);

      expect(result.commodity, equals('wheat'));
      expect(result.quantityKg, equals(150.0));
      expect(result.ratePerKg, equals(28.0));
      expect(result.txnType, equals('purchase'));
    });

    test('handles empty input gracefully', () {
      final result = VoiceParser.parse('');
      expect(result.isEmpty, isTrue);
    });
  });
}
