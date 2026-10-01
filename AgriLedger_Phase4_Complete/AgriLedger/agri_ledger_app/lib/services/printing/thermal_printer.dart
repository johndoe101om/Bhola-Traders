// lib/services/printing/thermal_printer.dart
//
// Connects to ESC/POS Bluetooth thermal printers (58mm / 80mm rolls).
// Common models supported: Xprinter, GOOJPRT, Rongta, MUNBYN.
//
// Uses flutter_blue_plus for BLE GATT writes.
// Classic Bluetooth SPP printers use a different channel — see note below.
//
// NOTE: Most cheap Indian thermal printers use Classic BT SPP (not BLE).
// For SPP printers, use the 'bluetooth_print' package instead.
// This file handles BLE GATT printers. The API is identical from caller side.

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// ── ESC/POS COMMAND BYTES ─────────────────────────────────────────────

class EscPos {
  // Initialize
  static final init = Uint8List.fromList([0x1B, 0x40]);
  // Line feed
  static final lf = Uint8List.fromList([0x0A]);
  // Cut paper (full)
  static final cut = Uint8List.fromList([0x1D, 0x56, 0x00]);
  // Cut paper (partial)
  static final partialCut = Uint8List.fromList([0x1D, 0x56, 0x01]);
  // Bold ON
  static final boldOn = Uint8List.fromList([0x1B, 0x45, 0x01]);
  // Bold OFF
  static final boldOff = Uint8List.fromList([0x1B, 0x45, 0x00]);
  // Align center
  static final alignCenter = Uint8List.fromList([0x1B, 0x61, 0x01]);
  // Align left
  static final alignLeft = Uint8List.fromList([0x1B, 0x61, 0x00]);
  // Align right
  static final alignRight = Uint8List.fromList([0x1B, 0x61, 0x02]);
  // Double height + width (large text)
  static final textLarge = Uint8List.fromList([0x1D, 0x21, 0x11]);
  // Normal text size
  static final textNormal = Uint8List.fromList([0x1D, 0x21, 0x00]);
  // Text large (height only)
  static final textMedium = Uint8List.fromList([0x1D, 0x21, 0x01]);
  // Divider line (32 dashes for 58mm)
  static Uint8List get divider =>
      Uint8List.fromList('--------------------------------\n'.codeUnits);

  static Uint8List text(String t) => Uint8List.fromList(t.codeUnits);
  static Uint8List line(String t) => Uint8List.fromList('$t\n'.codeUnits);
  static Uint8List spaces(int n) => Uint8List.fromList(List.filled(n, 0x20));
}

// ── PRINTER STATUS ────────────────────────────────────────────────────

enum PrinterStatus {
  disconnected,
  scanning,
  connecting,
  connected,
  printing,
  error,
}

class PrinterDevice {
  final String id;
  final String name;
  final int rssi;
  const PrinterDevice(
      {required this.id, required this.name, required this.rssi});
}

// ── THERMAL PRINTER SERVICE ───────────────────────────────────────────

class ThermalPrinterService extends ChangeNotifier {
  PrinterStatus _status = PrinterStatus.disconnected;
  BluetoothDevice? _device;
  BluetoothCharacteristic? _characteristic;
  String? _errorMessage;
  List<PrinterDevice> _foundDevices = [];

  PrinterStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<PrinterDevice> get foundDevices => _foundDevices;
  bool get isConnected => _status == PrinterStatus.connected;
  String? get connectedDeviceName => _device?.platformName;

  // ── SCAN ──────────────────────────────────────────────────────────
  Future<void> startScan(
      {Duration timeout = const Duration(seconds: 8)}) async {
    _foundDevices = [];
    _setStatus(PrinterStatus.scanning);

    try {
      await FlutterBluePlus.startScan(timeout: timeout);

      FlutterBluePlus.scanResults.listen((results) {
        final devices = results
            .where((r) => r.device.platformName.isNotEmpty || r.rssi > -80)
            .map((r) => PrinterDevice(
                  id: r.device.remoteId.str,
                  name: r.device.platformName.isEmpty
                      ? 'Unknown (${r.device.remoteId.str.substring(0, 8)})'
                      : r.device.platformName,
                  rssi: r.rssi,
                ))
            .toList();

        _foundDevices = devices;
        notifyListeners();
      });

      await Future.delayed(timeout);
      await FlutterBluePlus.stopScan();
      _setStatus(PrinterStatus.disconnected);
    } catch (e) {
      _errorMessage = 'Scan failed: $e';
      _setStatus(PrinterStatus.error);
    }
  }

  // ── CONNECT ───────────────────────────────────────────────────────
  Future<bool> connect(String deviceId) async {
    _setStatus(PrinterStatus.connecting);
    try {
      final results = await FlutterBluePlus.scanResults.first;
      final scanResult = results.firstWhere(
        (r) => r.device.remoteId.str == deviceId,
        orElse: () => throw Exception('Device not found'),
      );

      _device = scanResult.device;
      await _device!.connect(timeout: const Duration(seconds: 10));

      // Discover services + find write characteristic
      final services = await _device!.discoverServices();
      for (final service in services) {
        for (final char in service.characteristics) {
          if (char.properties.write || char.properties.writeWithoutResponse) {
            _characteristic = char;
            break;
          }
        }
        if (_characteristic != null) break;
      }

      if (_characteristic == null) {
        throw Exception('No writable characteristic found on this printer');
      }

      _setStatus(PrinterStatus.connected);

      // Save device ID for reconnect
      debugPrint('[Printer] Connected: ${_device!.platformName}');
      return true;
    } catch (e) {
      _errorMessage = 'Connection failed: $e';
      _setStatus(PrinterStatus.error);
      return false;
    }
  }

  // ── DISCONNECT ────────────────────────────────────────────────────
  Future<void> disconnect() async {
    await _device?.disconnect();
    _device = null;
    _characteristic = null;
    _setStatus(PrinterStatus.disconnected);
  }

  // ── PRINT BYTES ───────────────────────────────────────────────────
  Future<bool> _printBytes(Uint8List bytes) async {
    if (_characteristic == null) return false;
    _setStatus(PrinterStatus.printing);

    try {
      // Chunk into 512-byte packets (BLE MTU limit)
      const chunkSize = 512;
      for (int i = 0; i < bytes.length; i += chunkSize) {
        final end = (i + chunkSize).clamp(0, bytes.length);
        final chunk = bytes.sublist(i, end);
        await _characteristic!.write(chunk, withoutResponse: true);
        await Future.delayed(
            const Duration(milliseconds: 20)); // let printer breathe
      }
      _setStatus(PrinterStatus.connected);
      return true;
    } catch (e) {
      _errorMessage = 'Print failed: $e';
      _setStatus(PrinterStatus.error);
      return false;
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // PRINT: TRANSACTION RECEIPT (58mm thermal)
  // ──────────────────────────────────────────────────────────────────

  Future<bool> printTransactionReceipt({
    required String partyName,
    required String txnType,
    required double amount,
    required String direction,
    String? commodity,
    double? quantityKg,
    double? ratePerKg,
    required String date,
    String? paymentMode,
    String? notes,
    String businessName = 'Bhola Traders',
  }) async {
    final buf = BytesBuilder();

    void add(Uint8List b) => buf.add(b);
    void addLine(String s) => buf.add(EscPos.line(s));

    // Init
    add(EscPos.init);
    add(EscPos.alignCenter);

    // Business name (large)
    add(EscPos.textLarge);
    add(EscPos.boldOn);
    addLine(businessName);
    add(EscPos.textNormal);
    add(EscPos.boldOff);
    addLine('Bhola Traders - Trust Quality Growth');
    add(EscPos.lf);

    add(EscPos.divider);

    // Receipt details (left-aligned)
    add(EscPos.alignLeft);
    addLine('Party: $partyName');
    addLine('Date:  $date');
    add(EscPos.divider);

    // Transaction type
    add(EscPos.boldOn);
    addLine(_txnLabel(txnType));
    add(EscPos.boldOff);

    if (commodity != null) {
      addLine('Item:  ${_commodityEmoji(commodity)} $commodity');
    }
    if (quantityKg != null) {
      addLine('Wt:    ${quantityKg.toStringAsFixed(1)} KG');
    }
    if (ratePerKg != null) {
      addLine('Rate:  Rs.${ratePerKg.toStringAsFixed(0)}/KG');
    }
    if (paymentMode != null) {
      addLine('Mode:  ${paymentMode.toUpperCase()}');
    }
    if (notes != null && notes.isNotEmpty) {
      addLine('Note:  $notes');
    }

    add(EscPos.divider);

    // AMOUNT (large)
    add(EscPos.alignCenter);
    add(EscPos.textLarge);
    add(EscPos.boldOn);
    addLine('Rs.${amount.toStringAsFixed(0)}');
    add(EscPos.textNormal);
    add(EscPos.boldOff);
    addLine(direction == 'in' ? '(Received / Mila)' : '(Paid / Diya)');

    add(EscPos.divider);
    addLine('Thank you / Dhanyavaad');
    add(EscPos.lf);
    add(EscPos.lf);
    add(EscPos.lf);
    add(EscPos.partialCut);

    return _printBytes(buf.toBytes());
  }

  // ──────────────────────────────────────────────────────────────────
  // PRINT: PARTY BALANCE SLIP (quick)
  // ──────────────────────────────────────────────────────────────────

  Future<bool> printBalanceSlip({
    required String partyName,
    required double balance,
    required int bagsOutstanding,
    String businessName = 'Bhola Traders',
  }) async {
    final buf = BytesBuilder();

    void add(Uint8List b) => buf.add(b);
    void addLine(String s) => buf.add(EscPos.line(s));

    add(EscPos.init);
    add(EscPos.alignCenter);
    add(EscPos.boldOn);
    addLine(businessName);
    add(EscPos.boldOff);
    add(EscPos.divider);

    add(EscPos.alignLeft);
    addLine('Party: $partyName');
    add(EscPos.divider);

    add(EscPos.alignCenter);
    add(EscPos.textLarge);
    add(EscPos.boldOn);
    addLine('Rs.${balance.abs().toStringAsFixed(0)}');
    add(EscPos.textNormal);
    add(EscPos.boldOff);
    addLine(balance >= 0 ? 'Hamara Baaki' : 'Unka Baaki');

    if (bagsOutstanding > 0) {
      add(EscPos.divider);
      addLine('Bori Baaki: $bagsOutstanding');
    }

    add(EscPos.divider);
    addLine(DateTime.now().toLocal().toString().substring(0, 16));
    add(EscPos.lf);
    add(EscPos.lf);
    add(EscPos.partialCut);

    return _printBytes(buf.toBytes());
  }

  // ──────────────────────────────────────────────────────────────────
  // PRINT: LABOUR PAYSLIP (58mm thermal)
  // ──────────────────────────────────────────────────────────────────

  Future<bool> printPayslipThermal({
    required String employeeName,
    required String role,
    required String wageType,
    required double baseRate,
    required String periodStr,
    required int presentDays,
    required int halfDays,
    required int absentDays,
    required double overtimeHours,
    required double earnedWage,
    required double cashPaid,
    required double onlinePaid,
    required double totalPaid,
    required double balanceDue,
    String businessName = 'Bhola Traders',
  }) async {
    final buf = BytesBuilder();

    void add(Uint8List b) => buf.add(b);
    void addLine(String s) => buf.add(EscPos.line(s));

    add(EscPos.init);
    add(EscPos.alignCenter);
    add(EscPos.boldOn);
    addLine(businessName);
    add(EscPos.boldOff);
    addLine('LABOUR PAYSLIP / MAJDURI PARCHI');
    add(EscPos.divider);

    add(EscPos.alignLeft);
    addLine('Emp: $employeeName (${role.toUpperCase()})');
    addLine('Rate: Rs.${baseRate.toStringAsFixed(0)} / $wageType');
    addLine('Period: $periodStr');
    add(EscPos.divider);

    addLine('ATTENDANCE / HAJIRI:');
    addLine(' Present:   $presentDays days');
    if (halfDays > 0) addLine(' Half-day:  $halfDays days');
    addLine(' Absent:    $absentDays days');
    if (overtimeHours > 0) {
      addLine(' Overtime:  ${overtimeHours.toStringAsFixed(1)} hrs');
    }
    add(EscPos.divider);

    addLine('EARNINGS / KAMAI:');
    addLine(' Gross Earned: Rs.${earnedWage.toStringAsFixed(0)}');
    add(EscPos.divider);

    addLine('PAYMENTS / BHUGTAN:');
    if (cashPaid > 0) addLine(' Cash:   Rs.${cashPaid.toStringAsFixed(0)}');
    if (onlinePaid > 0) addLine(' Online: Rs.${onlinePaid.toStringAsFixed(0)}');
    addLine(' Total Paid:   Rs.${totalPaid.toStringAsFixed(0)}');
    add(EscPos.divider);

    add(EscPos.alignCenter);
    add(EscPos.textLarge);
    add(EscPos.boldOn);
    addLine('Rs.${balanceDue.abs().toStringAsFixed(0)}');
    add(EscPos.textNormal);
    add(EscPos.boldOff);
    addLine(balanceDue > 0
        ? 'NET DUE (DENA HAI)'
        : balanceDue < 0
            ? 'ADVANCE (LE LIYA)'
            : 'ALL CLEARED (CHUKTA)');
    add(EscPos.divider);

    add(EscPos.alignLeft);
    add(EscPos.lf);
    addLine('Sign / Hastakshar: ________________');
    addLine(DateTime.now().toLocal().toString().substring(0, 16));
    add(EscPos.lf);
    add(EscPos.lf);
    add(EscPos.partialCut);

    return _printBytes(buf.toBytes());
  }

  // ── HELPERS ───────────────────────────────────────────────────────

  void _setStatus(PrinterStatus s) {
    _status = s;
    notifyListeners();
  }

  String _txnLabel(String type) => switch (type) {
        'purchase' => 'KHARIDI / PURCHASE',
        'sale' => 'BIKRI / SALE',
        'cash_in' => 'PAISA MILA / CASH IN',
        'cash_out' => 'PAISA DIYA / CASH OUT',
        _ => type.toUpperCase(),
      };

  String _commodityEmoji(String c) => switch (c) {
        'rice' => '[Rice]',
        'wheat' => '[Gehu]',
        'maize' => '[Makka]',
        _ => '',
      };

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
