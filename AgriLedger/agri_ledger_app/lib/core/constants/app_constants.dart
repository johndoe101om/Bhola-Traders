// lib/core/constants/app_constants.dart

/// All business constants, allowed values, and Hindi/English labels.
class AppConstants {
  AppConstants._();

  // ── API ─────────────────────────────────────────────────────
  static const String baseUrl =
      'http://192.168.1.11:5000'; // Change to your server IP
  static const String apiVersion = '/api/v1';
  static const String defaultPin = '9199';

  // ── BUSINESS ────────────────────────────────────────────────
  static const List<String> partyTypes = ['farmer', 'supplier', 'customer'];
  static const List<String> txnTypes = [
    'purchase',
    'sale',
    'cash_in',
    'cash_out'
  ];
  static const List<String> commodities = [
    'rice',
    'wheat',
    'maize',
    'jute',
    'moong_dal',
  ];
  static const List<String> paymentModes = ['cash', 'upi', 'credit'];
  static const List<String> bagMovements = ['given', 'returned'];

  // ── LABELS (Hindi / English) ─────────────────────────────────
  static const Map<String, String> partyTypeLabels = {
    'farmer': 'किसान\nFarmer',
    'supplier': 'सप्लायर\nSupplier',
    'customer': 'ग्राहक\nCustomer',
  };

  static const Map<String, String> txnTypeLabels = {
    'purchase': 'खरीदी\nPurchase',
    'sale': 'बिक्री\nSale',
    'cash_in': 'पैसा मिला\nCash In',
    'cash_out': 'पैसा दिया\nCash Out',
  };

  static const Map<String, String> commodityLabels = {
    'rice': 'चावल\nRice',
    'wheat': 'गेहूँ\nWheat',
    'maize': 'मक्का\nMaize',
    'jute': 'जूट\nJute',
    'moong_dal': 'मूँग दाल\nMoong Dal',
  };

  static const Map<String, String> commodityHindi = {
    'rice': 'चावल',
    'wheat': 'गेहूँ',
    'maize': 'मक्का',
    'jute': 'जूट',
    'moong_dal': 'मूँग दाल',
  };

  static const Map<String, String> commodityEnglish = {
    'rice': 'Rice',
    'wheat': 'Wheat',
    'maize': 'Maize',
    'jute': 'Jute',
    'moong_dal': 'Moong Dal',
  };

  static const Map<String, String> paymentModeLabels = {
    'cash': 'नकद / Cash',
    'upi': 'UPI',
    'credit': 'उधार / Credit',
  };

  static const Map<String, String> bagMovementLabels = {
    'given': 'बोरी दी\nBags Given',
    'returned': 'बोरी वापस\nBags Returned',
  };

  // Direction labels for balance display
  static const Map<String, String> balanceDirectionLabels = {
    'they_owe_us': 'हमारा बाकी है\n(They owe us)',
    'we_owe_them': 'उनका बाकी है\n(We owe them)',
    'settled': 'हिसाब बराबर\n(Settled)',
  };

  // ── COMMODITY ICONS ──────────────────────────────────────────
  static const Map<String, String> commodityEmoji = {
    'rice': '🌾',
    'wheat': '🌿',
    'maize': '🌽',
    'jute': '🧵',
    'moong_dal': '🫘',
  };

  // ── EMPLOYEES ────────────────────────────────────────────────
  static const List<String> employeeTypes = [
    'labour',
    'driver',
    'supervisor',
    'other'
  ];
  static const List<String> attendanceStatuses = [
    'present',
    'absent',
    'half_day',
    'overtime',
    'holiday'
  ];
  static const List<String> employeePaymentModes = [
    'cash',
    'upi',
    'bank_transfer'
  ];
  static const List<String> employeePaymentTypes = [
    'wage',
    'advance',
    'bonus',
    'deduction',
    'settlement'
  ];

  static const Map<String, String> employeeTypeLabels = {
    'labour': 'मज़दूर',
    'driver': 'ड्राइवर',
    'supervisor': 'सुपरवाइज़र',
    'other': 'अन्य',
  };
  static const Map<String, String> attendanceStatusLabels = {
    'present': 'उपस्थित',
    'absent': 'अनुपस्थित',
    'half_day': 'आधा दिन',
    'overtime': 'ओवरटाइम',
    'holiday': 'छुट्टी',
  };
  static const Map<String, String> employeePaymentTypeLabels = {
    'wage': 'मज़दूरी',
    'advance': 'एडवांस',
    'bonus': 'बोनस',
    'deduction': 'कटौती',
    'settlement': 'हिसाब',
  };

  // ── SUPABASE FALLBACK CONFIG ─────────────────────────────────
  static const String defaultSupabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://mmfrilhikotpssbtgees.supabase.co',
  );
  static const String defaultSupabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_-nhZTWlt7wMb3ytl1d03Sw_rA_W1ZgG',
  );
}
