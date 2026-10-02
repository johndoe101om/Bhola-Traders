// lib/services/voice_parser.dart
//
// Parses free-form Hindi/English speech into structured transaction data.
// Works 100% offline — no cloud NLP needed.
//
// Example inputs handled:
//   "राम लाल से 200 किलो चावल 22 रुपये किलो खरीदा"
//   "sharma ko 5000 rupees diya"
//   "ram lal se 3 bori li"
//   "suresh ko 150 kg gehu 21 rate pe becha"
//   "500 cash mila ramesh se"

class ParsedVoiceEntry {
  final String? partyName;
  final String?
      txnType; // purchase | sale | cash_in | cash_out | bag_given | bag_returned
  final String? commodity; // rice | wheat | maize
  final double? quantityKg;
  final double? ratePerKg;
  final double? amount;
  final int? bagCount;
  final String? paymentMode; // cash | upi | credit
  final String rawText;

  // Confidence 0.0–1.0: how sure we are about the parse
  final double confidence;

  const ParsedVoiceEntry({
    this.partyName,
    this.txnType,
    this.commodity,
    this.quantityKg,
    this.ratePerKg,
    this.amount,
    this.bagCount,
    this.paymentMode,
    required this.rawText,
    this.confidence = 0.5,
  });

  bool get isEmpty =>
      partyName == null &&
      txnType == null &&
      amount == null &&
      bagCount == null;

  ParsedVoiceEntry copyWith({
    String? partyName,
    String? txnType,
    String? commodity,
    double? quantityKg,
    double? ratePerKg,
    double? amount,
    int? bagCount,
    String? paymentMode,
    double? confidence,
  }) =>
      ParsedVoiceEntry(
        partyName: partyName ?? this.partyName,
        txnType: txnType ?? this.txnType,
        commodity: commodity ?? this.commodity,
        quantityKg: quantityKg ?? this.quantityKg,
        ratePerKg: ratePerKg ?? this.ratePerKg,
        amount: amount ?? this.amount,
        bagCount: bagCount ?? this.bagCount,
        paymentMode: paymentMode ?? this.paymentMode,
        rawText: rawText,
        confidence: confidence ?? this.confidence,
      );

  @override
  String toString() => 'party=$partyName type=$txnType commodity=$commodity '
      'qty=${quantityKg}kg rate=$ratePerKg amount=$amount bags=$bagCount '
      'confidence=${(confidence * 100).toStringAsFixed(0)}%';
}

// ─────────────────────────────────────────────────────────────────────────────

class VoiceParser {
  // ── COMMODITY KEYWORDS ────────────────────────────────────────────
  static const _commodityMap = <String, String>{
    // Rice / Paddy
    'चावल': 'rice', 'धान': 'rice', 'paddy': 'rice', 'rice': 'rice',
    'chawal': 'rice', 'dhan': 'rice', 'chaawal': 'rice',
// Wheat
    'गेहूं': 'wheat', 'गेहू': 'wheat', 'wheat': 'wheat',
    'gehu': 'wheat',
    // Maize
    'मक्का': 'maize', 'मक्के': 'maize', 'maize': 'maize',
    'makka': 'maize', 'makke': 'maize', 'corn': 'maize', 'bhutta': 'maize',
    // Jute
    'जूट': 'jute', 'पटसन': 'jute', 'jute': 'jute', 'jut': 'jute',
    // Moong Dal
    'मूंग': 'moong_dal', 'मूँग': 'moong_dal', 'मूंग दाल': 'moong_dal',
    'मूँग दाल': 'moong_dal', 'moong': 'moong_dal', 'mung': 'moong_dal',
    'moong dal': 'moong_dal', 'mung daal': 'moong_dal',
  };

  // ── PURCHASE KEYWORDS ─────────────────────────────────────────────
  static const _purchaseWords = [
    'खरीदा',
    'खरीदी',
    'खरीदे',
    'liya',
    'lia',
    'purchase',
    'kharida',
    'kharidi',
    'kharide',
    'लिया',
    'ली',
    'ले',
    'aaya',
    'आया',
    'mila',
  ];

  // ── SALE KEYWORDS ─────────────────────────────────────────────────
  static const _saleWords = [
    'बेचा',
    'बेची',
    'becha',
    'bechi',
    'sale',
    'diya',
    'दिया',
    'भेजा',
    'bheja',
    'sold',
    'supply',
    'nikala',
    'निकाला',
  ];

  // ── CASH IN KEYWORDS ─────────────────────────────────────────────
  static const _cashInWords = [
    'मिला',
    'मिली',
    'मिले',
    'received',
    'mila',
    'mili',
    'mile',
    'aaya',
    'आया',
    'payment mila',
    'paisa mila',
    'rupee mila',
    'cash mila',
  ];

  // ── CASH OUT KEYWORDS ─────────────────────────────────────────────
  static const _cashOutWords = [
    'दिया',
    'दी',
    'दिए',
    'दिये',
    'paid',
    'diya',
    'di',
    'diye',
    'die',
    'payment diya',
    'paisa diya',
    'rupee diya',
    'cash diya',
    'bheji',
    'bheja',
  ];

  // ── BAG KEYWORDS ──────────────────────────────────────────────────
  static const _bagWords = [
    'बोरी',
    'bori',
    'bag',
    'bags',
    'थैला',
    'thela',
    'बोरा',
    'bora',
    'बोरिया',
    'बोरियां',
    'boriya',
    'boriyan',
    'बारी',
    'bari',
    'बोरे',
    'bore',
    'बोर',
    'bor',
    'बैग',
  ];

  static const _bagGivenWords = [
    'दी',
    'दिया',
    'दिए',
    'diya',
    'di',
    'die',
    'given',
    'दिये',
  ];

  static const _bagReturnedWords = [
    'वापस',
    'वापस आई',
    'returned',
    'wapas',
    'vapas',
    'lautaya',
    'ली',
  ];

  // ── UNIT KEYWORDS ─────────────────────────────────────────────────
  static const _kgWords = [
    'किलो',
    'किलोग्राम',
    'kg',
    'kilo',
    'kilogram',
    'किलों',
  ];

  static const _rateWords = [
    'रेट',
    'रुपये',
    'रुपए',
    'rupye',
    'rupee',
    'rupees',
    'rate',
    'ka rate',
    'ke bhav',
    'भाव',
    'bhav',
    'price',
    'per',
    '@',
    'at',
  ];

  // ── PAYMENT MODE KEYWORDS ─────────────────────────────────────────
  static const _upiWords = [
    'upi',
    'online',
    'phonepe',
    'gpay',
    'paytm',
    'neft'
  ];
  static const _creditWords = [
    'उधार',
    'udhaar',
    'credit',
    'baad mein',
    'baaki'
  ];

  // ── HINDI NUMBER WORDS (for bag count etc.) ────────────────────────
  static const _hindiNumberWords = <String, String>{
    'एक': '1', 'दो': '2', 'तीन': '3', 'चार': '4', 'पांच': '5',
    'पाँच': '5', 'छह': '6', 'छः': '6', 'सात': '7', 'आठ': '8',
    'नौ': '9', 'दस': '10', 'ग्यारह': '11', 'बारह': '12',
    'तेरह': '13', 'चौदह': '14', 'पंद्रह': '15', 'बीस': '20',
    'पच्चीस': '25', 'तीस': '30', 'पचास': '50', 'सौ': '100',
    // Romanized Hindi numbers
    'ek': '1', 'do': '2', 'teen': '3', 'char': '4', 'paanch': '5',
    'panch': '5', 'cheh': '6', 'saat': '7', 'aath': '8',
    'nau': '9', 'das': '10',
  };

  // ── PARTY EXTRACTION PATTERNS ─────────────────────────────────────
  // e.g. "राम लाल से", "sharma ko", "suresh bhai ne"
  // NOTE: Using (?:^|\s) instead of \b because \b doesn't work with Devanagari
  static final _partyBeforePatterns = [
    // Devanagari names: "शंकर को", "राम लाल से"
    RegExp(r'([\u0900-\u097F]+(?:\s+[\u0900-\u097F]+)*)\s+(?:से|को|ने)',
        caseSensitive: false),
    // Latin names: "sharma ko", "Ram Lal se"
    RegExp(r'([a-zA-Z]+(?:\s+[a-zA-Z]+)*)\s+(?:se|ko|ne)\b',
        caseSensitive: false),
  ];
  static final _partyAfterPatterns = [
    // "को शंकर", "se sharma"
    RegExp(r'(?:से|को|se|ko)\s+([\u0900-\u097F]+(?:\s+[\u0900-\u097F]+)*)',
        caseSensitive: false),
    RegExp(r'(?:se|ko)\s+([a-zA-Z]+(?:\s+[a-zA-Z]+)*)\b', caseSensitive: false),
  ];

  // ─────────────────────────────────────────────────────────────────
  // MAIN PARSE METHOD
  // ─────────────────────────────────────────────────────────────────

  static ParsedVoiceEntry parse(String rawText) {
    final text = _normalizeText(rawText);
    int confidence = 0;

    // Step 1: Extract commodity
    final commodity = _extractCommodity(text);
    if (commodity != null) confidence += 20;

    // Step 2: Extract numbers (qty, rate, amount)
    final numbers = _extractNumbers(text);

    // Step 3: Extract transaction type
    final txnType = _extractTxnType(text, hasCommodity: commodity != null);
    if (txnType != null) confidence += 25;

    // Step 4: Extract kg quantity and rate
    double? quantityKg;
    double? ratePerKg;
    double? amount;

    if (commodity != null && numbers.isNotEmpty) {
      final kgIdx = _findKgIndex(text);
      final rateIdx = _findRateIndex(text);

      if (kgIdx >= 0 && numbers.isNotEmpty) {
        quantityKg = _findNumberNear(text, numbers, kgIdx);
        confidence += 15;
      }
      if (rateIdx >= 0 && numbers.length >= 2) {
        ratePerKg =
            _findNumberNear(text, numbers, rateIdx, exclude: quantityKg);
        confidence += 15;
      }
      // Auto-calculate amount
      if (quantityKg != null && ratePerKg != null) {
        amount = quantityKg * ratePerKg;
        confidence += 10;
      } else if (numbers.length == 1) {
        amount = numbers.first;
      }
    } else if (numbers.isNotEmpty) {
      // Cash transaction: single number is the amount
      amount = numbers.reduce((a, b) => a > b ? a : b); // largest number
      if (amount > 0) confidence += 20;
    }

    // Step 5: Extract bag count
    int? bagCount;
    final bagIdx = _findBagIndex(text);
    if (bagIdx >= 0) {
      bagCount = _findIntNear(text, numbers, bagIdx)?.toInt();
      if (bagCount != null && bagCount > 0) confidence += 20;
    }

    // Step 6: Extract party name
    final partyName = _extractPartyName(text, rawText);
    if (partyName != null && partyName.length > 1) confidence += 15;

    // Step 7: Payment mode
    final paymentMode = _extractPaymentMode(text);

    // Use txnType as-is — bag detection is now handled inside _extractTxnType
    String? finalTxnType = txnType;

    return ParsedVoiceEntry(
      partyName: partyName,
      txnType: finalTxnType,
      commodity: commodity,
      quantityKg: quantityKg,
      ratePerKg: ratePerKg,
      amount: amount,
      bagCount: bagCount,
      paymentMode: paymentMode,
      rawText: rawText,
      confidence: (confidence / 100).clamp(0.0, 1.0),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────

  /// Normalize text: Hindi digits → Arabic, Hindi number words → digits, lowercase
  static String _normalizeText(String text) {
    const hindi = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
    var result = text.toLowerCase().trim();
    for (int i = 0; i < hindi.length; i++) {
      result = result.replaceAll(hindi[i], '$i');
    }
    // Convert Hindi number words to digits (e.g. "तीन" → "3")
    for (final entry in _hindiNumberWords.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    // Normalize common speech-to-text variations
    result = result
        .replaceAll('rupye', 'rupees')
        .replaceAll('rupaya', 'rupees')
        .replaceAll('rupaiye', 'rupees')
        .replaceAll('रुपय', 'रुपये')
        .replaceAll('किलोग्राम', 'किलो');
    return result;
  }

  /// Extract commodity keyword
  static String? _extractCommodity(String text) {
    for (final entry in _commodityMap.entries) {
      if (text.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    return null;
  }

  /// Extract all numbers from text (handles decimals)
  static List<double> _extractNumbers(String text) {
    return RegExp(r'\d+\.?\d*')
        .allMatches(text)
        .map((m) => double.tryParse(m.group(0)!))
        .whereType<double>()
        .where((n) => n > 0)
        .toList();
  }

  /// Detect transaction type from keywords
  static String? _extractTxnType(String text, {required bool hasCommodity}) {
    // Check BAG keywords FIRST — words like 'diya'/'di' overlap with cash_out
    final hasBag = _bagWords.any((w) => text.contains(w.toLowerCase()));
    if (hasBag) {
      final isBagReturned = _bagReturnedWords.any((w) => text.contains(w));
      final isBagGiven = _bagGivenWords.any((w) => text.contains(w));
      if (isBagReturned) return 'bag_returned';
      if (isBagGiven) return 'bag_given';
      return 'bag_given'; // default bag direction
    }

    if (hasCommodity) {
      if (_purchaseWords.any((w) => text.contains(w))) return 'purchase';
      if (_saleWords.any((w) => text.contains(w))) return 'sale';
    }
    // Cash-only
    if (_cashInWords.any((w) => text.contains(w))) return 'cash_in';
    if (_cashOutWords.any((w) => text.contains(w))) return 'cash_out';
    // Grain fallback
    if (hasCommodity) {
      if (_saleWords.any((w) => text.contains(w))) return 'sale';
      if (_purchaseWords.any((w) => text.contains(w))) return 'purchase';
      // Default to purchase if commodity found but no direction keyword
      return 'purchase';
    }
    return null;
  }

  /// Find index of kg keyword in text
  static int _findKgIndex(String text) {
    for (final word in _kgWords) {
      final idx = text.indexOf(word.toLowerCase());
      if (idx >= 0) return idx;
    }
    return -1;
  }

  /// Find index of rate keyword in text
  static int _findRateIndex(String text) {
    for (final word in _rateWords) {
      if (word == 'at') {
        final match = RegExp(r'(?:^|\s)at\s+').firstMatch(text);
        if (match != null) return match.start;
        continue;
      }
      final idx = text.indexOf(word.toLowerCase());
      if (idx >= 0) return idx;
    }
    return -1;
  }

  /// Find index of bag keyword in text
  static int _findBagIndex(String text) {
    for (final word in _bagWords) {
      final idx = text.indexOf(word.toLowerCase());
      if (idx >= 0) return idx;
    }
    return -1;
  }

  /// Find the number closest (before) a keyword position
  static double? _findNumberNear(
      String text, List<double> numbers, int keywordIdx,
      {double? exclude}) {
    if (numbers.isEmpty) return null;
    // Find all number positions in the text
    final matches = RegExp(r'\d+\.?\d*').allMatches(text).toList();
    double? best;
    int bestDist = 999999;

    for (final match in matches) {
      final val = double.tryParse(match.group(0)!);
      if (val == null || val == 0) continue;
      if (exclude != null && val == exclude) continue;
      final dist = (match.start - keywordIdx).abs();
      if (dist < bestDist) {
        bestDist = dist;
        best = val;
      }
    }
    return best;
  }

  static double? _findIntNear(
      String text, List<double> numbers, int keywordIdx) {
    return _findNumberNear(text, numbers, keywordIdx);
  }

  /// Check if string is a pure number (should not be a party name)
  static bool _isPureNumber(String text) {
    return RegExp(r'^\d+\.?\d*$').hasMatch(text.trim());
  }

  /// Extract party name using postposition patterns (se, ko, ne)
  static String? _extractPartyName(String normalizedText, String originalText) {
    // Try "before" patterns first ("शंकर को", "Ram se")
    for (final pattern in _partyBeforePatterns) {
      final match = pattern.firstMatch(originalText);
      if (match != null) {
        final name = match.group(1)?.trim();
        if (name != null &&
            name.length > 1 &&
            !_isKeyword(name.toLowerCase()) &&
            !_isPureNumber(name)) {
          return _toTitleCase(name);
        }
      }
    }
    // Also try on normalized text (for case-insensitive matching)
    for (final pattern in _partyBeforePatterns) {
      final match = pattern.firstMatch(normalizedText);
      if (match != null) {
        final name = match.group(1)?.trim();
        if (name != null &&
            name.length > 1 &&
            !_isKeyword(name.toLowerCase()) &&
            !_isPureNumber(name)) {
          return _toTitleCase(name);
        }
      }
    }
    // Try "after" patterns ("ko Shankar", "से राम")
    for (final pattern in _partyAfterPatterns) {
      final match = pattern.firstMatch(originalText);
      if (match != null) {
        final name = match.group(1)?.trim();
        if (name != null &&
            name.length > 1 &&
            !_isKeyword(name.toLowerCase()) &&
            !_isPureNumber(name)) {
          return _toTitleCase(name);
        }
      }
    }
    for (final pattern in _partyAfterPatterns) {
      final match = pattern.firstMatch(normalizedText);
      if (match != null) {
        final name = match.group(1)?.trim();
        if (name != null &&
            name.length > 1 &&
            !_isKeyword(name.toLowerCase()) &&
            !_isPureNumber(name)) {
          return _toTitleCase(name);
        }
      }
    }
    return null;
  }

  static bool _isKeyword(String word) {
    final keywords = {
      ..._commodityMap.keys.map((k) => k.toLowerCase()),
      'kg', 'kilo', 'rupees', 'rate', 'purchase', 'sale',
      'cash', 'upi', 'bori', 'bag', 'bags',
      // Hindi number words should not be party names
      ..._hindiNumberWords.keys,
      // Bag-related words
      'बोरी', 'बोरा', 'थैला',
    };
    return keywords.contains(word);
  }

  static String _toTitleCase(String text) {
    return text
        .split(' ')
        .map((w) => w.isEmpty
            ? w
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  static String? _extractPaymentMode(String text) {
    // Don't assign payment mode for bag transactions
    if (_bagWords.any((w) => text.contains(w.toLowerCase()))) return null;
    if (_upiWords.any((w) => text.contains(w))) return 'upi';
    if (_creditWords.any((w) => text.contains(w))) return 'credit';
    return 'cash'; // default for money transactions
  }

  // ─────────────────────────────────────────────────────────────────
  // TEST CASES (for development validation)
  // ─────────────────────────────────────────────────────────────────

  static void runTests() {
    final cases = [
      (
        'राम लाल से 200 किलो चावल 22 रुपये किलो खरीदा',
        'purchase/rice/200kg/22rate'
      ),
      ('sharma ko 5000 rupees diya', 'cash_out/5000'),
      ('suresh ne 3 bori di', 'bag_given/3'),
      ('150 kg gehu 21 rate pe becha ramesh ko', 'sale/wheat/150kg/21rate'),
      ('500 cash mila ram se', 'cash_in/500'),
      ('makka 100 kg liya 18 rupye', 'purchase/maize/100kg/18rate'),
    ];

    for (final (input, expected) in cases) {
      final result = parse(input);
      // ignore: avoid_print
      print('Input:    $input');
      // ignore: avoid_print
      print('Expected: $expected');
      // ignore: avoid_print
      print('Got:      $result\n');
    }
  }
}
