// lib/services/voice_service.dart
//
// Manages the speech_to_text plugin lifecycle.
// Works offline using Android's on-device recognition engine.
// Supports Hindi (hi_IN) with English fallback words.

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

enum VoiceState {
  idle,
  initializing,
  listening,
  processing,
  done,
  error,
  notAvailable,
}

class VoiceService extends ChangeNotifier {
  final SpeechToText _stt = SpeechToText();

  VoiceState _state = VoiceState.idle;
  String _transcript = '';
  String? _errorMessage;
  bool _initialized = false;

  VoiceState get state => _state;
  String get transcript => _transcript;
  String? get errorMessage => _errorMessage;
  bool get isListening => _state == VoiceState.listening;
  bool get isAvailable => _initialized;

  // ── INITIALIZE ─────────────────────────────────────────────────
  Future<bool> initialize() async {
    if (_initialized) return true;
    _setState(VoiceState.initializing);

    try {
      final available = await _stt.initialize(
        onStatus: _onStatus,
        onError: _onError,
        debugLogging: kDebugMode,
      );

      if (available) {
        _initialized = true;
        _setState(VoiceState.idle);
        return true;
      } else {
        _setState(VoiceState.notAvailable);
        _errorMessage = 'Speech recognition not available on this device';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _setState(VoiceState.error);
      _errorMessage = 'Failed to initialize voice: $e';
      notifyListeners();
      return false;
    }
  }

  // ── START LISTENING ────────────────────────────────────────────
  Future<void> startListening({
    void Function(String transcript)? onResult,
    void Function(String error)? onError,
    String locale = 'hi_IN',           // Hindi — Android on-device
    Duration listenFor = const Duration(seconds: 12),
    Duration pauseFor = const Duration(seconds: 3),
  }) async {
    if (!_initialized) {
      final ok = await initialize();
      if (!ok) {
        onError?.call(_errorMessage ?? 'Not available');
        return;
      }
    }

    if (_stt.isListening) await _stt.stop();

    _transcript = '';
    _errorMessage = null;
    _setState(VoiceState.listening);

    await _stt.listen(
      onResult: (SpeechRecognitionResult result) {
        _transcript = result.recognizedWords;
        notifyListeners();

        if (result.finalResult) {
          _setState(VoiceState.done);
          onResult?.call(_transcript);
        }
      },
      localeId: locale,
      listenFor: listenFor,
      pauseFor: pauseFor,
      cancelOnError: true,
      partialResults: true, // show live transcript
      onSoundLevelChange: null,
    );
  }

  // ── STOP ───────────────────────────────────────────────────────
  Future<void> stop() async {
    await _stt.stop();
    _setState(VoiceState.idle);
  }

  Future<void> cancel() async {
    await _stt.cancel();
    _transcript = '';
    _setState(VoiceState.idle);
  }

  // ── STATUS CALLBACKS ───────────────────────────────────────────
  void _onStatus(String status) {
    debugPrint('[VoiceService] status: $status');
    switch (status) {
      case 'listening':
        if (_state != VoiceState.listening) _setState(VoiceState.listening);
      case 'notListening':
      case 'done':
        if (_state == VoiceState.listening) _setState(VoiceState.processing);
    }
  }

  void _onError(SpeechRecognitionError error) {
    debugPrint('[VoiceService] error: ${error.errorMsg}');
    _errorMessage = _friendlyError(error.errorMsg);
    _setState(VoiceState.error);
    notifyListeners();
  }

  String _friendlyError(String errorMsg) => switch (errorMsg) {
    'error_no_match'      => 'कुछ नहीं सुना / Nothing heard — try again',
    'error_speech_timeout'=> 'कोई आवाज़ नहीं / No speech detected',
    'error_network'       => 'इंटरनेट नहीं / Network error — use offline mode',
    'error_audio'         => 'माइक की समस्या / Microphone error',
    'error_not_recognized'=> 'पहचान नहीं हुई / Could not recognize speech',
    _ => 'Voice error: $errorMsg',
  };

  void _setState(VoiceState s) {
    _state = s;
    notifyListeners();
  }

  void reset() {
    _transcript = '';
    _errorMessage = null;
    _setState(VoiceState.idle);
  }

  @override
  void dispose() {
    _stt.stop();
    super.dispose();
  }
}
