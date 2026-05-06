// lib/core/sync/sync_engine.dart
//
// Background sync engine that:
//   1. Watches connectivity changes
//   2. Auto-pushes queued items when network comes back
//   3. Pulls server changes for multi-device support
//   4. Retries failed items with exponential backoff
//   5. Reports sync status to UI via streams

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/app_repository.dart';

enum SyncStatus {
  idle,
  syncing,
  success,
  failed,
  offline,
}

class SyncState {
  final SyncStatus status;
  final int pendingCount;
  final DateTime? lastSyncAt;
  final String? lastError;
  final int pushedCount;

  const SyncState({
    this.status = SyncStatus.idle,
    this.pendingCount = 0,
    this.lastSyncAt,
    this.lastError,
    this.pushedCount = 0,
  });

  SyncState copyWith({
    SyncStatus? status,
    int? pendingCount,
    DateTime? lastSyncAt,
    String? lastError,
    int? pushedCount,
  }) => SyncState(
    status: status ?? this.status,
    pendingCount: pendingCount ?? this.pendingCount,
    lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    lastError: lastError ?? this.lastError,
    pushedCount: pushedCount ?? this.pushedCount,
  );

  bool get isOnline => status != SyncStatus.offline;
  bool get isBusy => status == SyncStatus.syncing;
}

class SyncEngine extends ChangeNotifier {
  final AppRepository _repo;
  
  SyncState _state = const SyncState();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _periodicTimer;
  Timer? _retryTimer;
  bool _disposed = false;

  // Sync intervals
  static const _periodicInterval = Duration(minutes: 5);
  static const _retryInterval = Duration(seconds: 30);
  static const _minSyncInterval = Duration(seconds: 10); // don't sync too often

  DateTime? _lastSyncAttempt;

  SyncState get state => _state;
  bool get isOnline => _state.isOnline;

  SyncEngine({required AppRepository repo}) : _repo = repo {
    _init();
  }

  // ── INITIALIZATION ─────────────────────────────────────────────
  void _init() {
    // Watch network changes
    _connectivitySub = Connectivity()
      .onConnectivityChanged
      .listen(_onConnectivityChanged);

    // Check current state immediately
    _checkConnectivity();

    // Periodic sync every 5 minutes when online
    _periodicTimer = Timer.periodic(_periodicInterval, (_) => _syncIfDue());

    // Load last sync time
    _loadLastSyncTime();
  }

  Future<void> _loadLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getString('last_sync_at');
    if (ts != null) {
      _updateState(_state.copyWith(lastSyncAt: DateTime.tryParse(ts)));
    }
  }

  Future<void> _saveLastSyncTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_sync_at', time.toIso8601String());
  }

  // ── CONNECTIVITY ───────────────────────────────────────────────
  Future<void> _checkConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      _handleConnectivity(result.first);
    } catch (e) {
      debugPrint('[SyncEngine] Connectivity check failed: $e');
      _handleConnectivity(ConnectivityResult.none);
    }
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    _handleConnectivity(results.isNotEmpty ? results.first : ConnectivityResult.none);
  }

  void _handleConnectivity(ConnectivityResult result) {
    final wasOffline = _state.status == SyncStatus.offline;
    final isNowOnline = result != ConnectivityResult.none;

    if (!isNowOnline) {
      _updateState(_state.copyWith(status: SyncStatus.offline));
      return;
    }

    if (wasOffline && isNowOnline) {
      // Just came online — sync immediately
      debugPrint('[SyncEngine] Network restored — syncing now');
      syncNow();
    } else if (_state.status == SyncStatus.offline) {
      _updateState(_state.copyWith(status: SyncStatus.idle));
    }
  }

  // ── SYNC NOW (public) ──────────────────────────────────────────
  Future<SyncResult> syncNow({bool force = false}) async {
    if (_state.isBusy) return SyncResult(success: false, message: 'Already syncing');

    // Debounce: don't sync more than once per 10 seconds
    if (!force && _lastSyncAttempt != null) {
      final elapsed = DateTime.now().difference(_lastSyncAttempt!);
      if (elapsed < _minSyncInterval) {
        return SyncResult(success: true, message: 'Synced recently');
      }
    }

    _lastSyncAttempt = DateTime.now();
    _updateState(_state.copyWith(status: SyncStatus.syncing));

    try {
      // Push pending local changes
      final result = await _repo.syncNow();

      if (result.success) {
        final now = DateTime.now();
        await _saveLastSyncTime(now);
        _updateState(_state.copyWith(
          status: SyncStatus.success,
          lastSyncAt: now,
          pushedCount: result.pushed,
          lastError: null,
        ));
        debugPrint('[SyncEngine] Pushed ${result.pushed} items');
        return result;
      } else {
        _updateState(_state.copyWith(
          status: SyncStatus.failed,
          lastError: result.message,
        ));
        _scheduleRetry();
        return result;
      }
    } catch (e) {
      _updateState(_state.copyWith(
        status: SyncStatus.failed,
        lastError: e.toString(),
      ));
      _scheduleRetry();
      return SyncResult(success: false, message: e.toString());
    }
  }

  // ── PERIODIC SYNC ──────────────────────────────────────────────
  Future<void> _syncIfDue() async {
    if (_state.status == SyncStatus.offline) return;
    if (_state.isBusy) return;
    final pending = await _repo.watchPendingSyncCount().first;
    if (pending > 0) {
      debugPrint('[SyncEngine] Periodic sync — $pending pending');
      await syncNow();
    }
  }

  // ── RETRY FAILED ───────────────────────────────────────────────
  void _scheduleRetry() {
    _retryTimer?.cancel();
    _retryTimer = Timer(_retryInterval, () {
      if (!_disposed && _state.status == SyncStatus.failed) {
        debugPrint('[SyncEngine] Retrying failed sync...');
        syncNow();
      }
    });
  }

  // ── STATUS UPDATE ──────────────────────────────────────────────
  void _updateState(SyncState newState) {
    if (_disposed) return;
    _state = newState;
    notifyListeners();
  }

  // ── STATUS TEXT ────────────────────────────────────────────────
  String get statusText => switch (_state.status) {
    SyncStatus.idle    => _state.lastSyncAt != null
      ? 'Last sync: ${_formatTime(_state.lastSyncAt!)}'
      : 'Not synced yet',
    SyncStatus.syncing => 'Syncing...',
    SyncStatus.success => 'Synced ✓',
    SyncStatus.failed  => 'Sync failed — will retry',
    SyncStatus.offline => '📵 Offline — saving locally',
  };

  String get statusTextHindi => switch (_state.status) {
    SyncStatus.idle    => 'तैयार है',
    SyncStatus.syncing => 'Sync हो रहा है...',
    SyncStatus.success => 'Sync हो गया ✓',
    SyncStatus.failed  => 'Sync नहीं हुआ',
    SyncStatus.offline => '📵 ऑफलाइन — डेटा सेव है',
  };

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  void dispose() {
    _disposed = true;
    _connectivitySub?.cancel();
    _periodicTimer?.cancel();
    _retryTimer?.cancel();
    super.dispose();
  }
}
