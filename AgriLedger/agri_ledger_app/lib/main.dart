// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/pin_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables safely
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('[Main] Note: .env file not loaded ($e), using default constants');
  }

  // Initialize Supabase with env or AppConstants fallback
  final supabaseUrl = (dotenv.env['SUPABASE_URL']?.isNotEmpty == true)
      ? dotenv.env['SUPABASE_URL']!
      : AppConstants.defaultSupabaseUrl;
  final supabaseKey = (dotenv.env['SUPABASE_ANON_KEY']?.isNotEmpty == true)
      ? dotenv.env['SUPABASE_ANON_KEY']!
      : AppConstants.defaultSupabaseAnonKey;

  if (supabaseUrl.isNotEmpty && supabaseUrl != 'YOUR_SUPABASE_PROJECT_URL') {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseKey,
      );
      debugPrint('[Main] Supabase initialized successfully at $supabaseUrl');
    } catch (e) {
      debugPrint('[Main] Supabase initialization error: $e');
    }
  }

  // Force portrait mode — village-friendly
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const ProviderScope(child: BholaTradersApp()));
}

class BholaTradersApp extends ConsumerWidget {
  const BholaTradersApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Bhola Traders',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _StartupRouter(),
    );
  }
}

/// Decides whether to show PIN screen or go straight to home.
/// If app was already authenticated in this session, skip PIN.
class _StartupRouter extends StatefulWidget {
  const _StartupRouter();

  @override
  State<_StartupRouter> createState() => _StartupRouterState();
}

class _StartupRouterState extends State<_StartupRouter> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString('user_pin');
    // If no PIN is set, pre-set the default and let user in directly on first launch
    if (pin == null) {
      await prefs.setString('user_pin', '1234');
    }
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppTheme.primary,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    return const PinScreen();
  }
}
