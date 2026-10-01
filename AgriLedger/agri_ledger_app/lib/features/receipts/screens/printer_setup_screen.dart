// lib/features/receipts/screens/printer_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_utils.dart';
import '../../../services/printing/thermal_printer.dart';

// ── Provider ─────────────────────────────────────────────────────────
final thermalPrinterProvider = ChangeNotifierProvider<ThermalPrinterService>(
  (ref) => ThermalPrinterService(),
);

class PrinterSetupScreen extends ConsumerStatefulWidget {
  const PrinterSetupScreen({super.key});

  @override
  ConsumerState<PrinterSetupScreen> createState() => _PrinterSetupScreenState();
}

class _PrinterSetupScreenState extends ConsumerState<PrinterSetupScreen> {
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    final allGranted = statuses.values.every((s) => s.isGranted);
    setState(() => _permissionsGranted = allGranted);

    if (!allGranted && mounted) {
      showError(context, 'Bluetooth permission required for printing');
    }
  }

  @override
  Widget build(BuildContext context) {
    final printer = ref.watch(thermalPrinterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🖨️ थर्मल प्रिंटर / Printer Setup'),
        actions: [
          if (printer.isConnected)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.circle, color: Colors.green[700], size: 10),
                  const SizedBox(width: 6),
                  Text('Connected',
                      style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── STATUS CARD ───────────────────────────────────────
          _StatusCard(printer: printer),
          const SizedBox(height: 16),

          // ── PERMISSIONS WARNING ───────────────────────────────
          if (!_permissionsGranted)
            Card(
              color: Colors.orange[50],
              child: ListTile(
                leading: Icon(Icons.warning_rounded, color: Colors.orange[700]),
                title: const Text('Bluetooth Permission Required',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle:
                    const Text('Tap to open Settings and grant permission'),
                onTap: openAppSettings,
              ),
            ),

          // ── SCAN BUTTON ───────────────────────────────────────
          ElevatedButton.icon(
            onPressed:
                _permissionsGranted && printer.status != PrinterStatus.scanning
                    ? () => ref.read(thermalPrinterProvider).startScan()
                    : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              minimumSize: const Size(double.infinity, 56),
            ),
            icon: printer.status == PrinterStatus.scanning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.bluetooth_searching_rounded,
                    color: Colors.white),
            label: Text(
              printer.status == PrinterStatus.scanning
                  ? 'खोज रहे हैं... / Scanning...'
                  : 'Bluetooth Scan करें / Scan',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 16),

          // ── DEVICE LIST ───────────────────────────────────────
          if (printer.foundDevices.isNotEmpty) ...[
            const Text('मिले डिवाइस / Found Devices',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            ...printer.foundDevices.map((device) => _DeviceTile(
                  device: device,
                  isConnected: printer.isConnected &&
                      printer.connectedDeviceName == device.name,
                  isConnecting: printer.status == PrinterStatus.connecting,
                  onTap: () => _connectTo(device.id),
                )),
          ],

          const SizedBox(height: 24),

          // ── TEST PRINT ────────────────────────────────────────
          if (printer.isConnected) ...[
            const Divider(),
            const SizedBox(height: 12),
            const Text('टेस्ट प्रिंट / Test Print',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final ok = await printer.printBalanceSlip(
                  partyName: 'Test Party',
                  balance: 1500.0,
                  bagsOutstanding: 3,
                );
                if (context.mounted) {
                  if (ok) {
                    showSuccess(context, 'Test print sent!');
                  } else {
                    showError(context, 'Print failed — check printer');
                  }
                }
              },
              icon: const Icon(Icons.print_rounded),
              label: const Text('Test Slip Print करें',
                  style: TextStyle(fontSize: 16)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                side: const BorderSide(color: AppTheme.primary),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => ref.read(thermalPrinterProvider).disconnect(),
              icon: Icon(Icons.bluetooth_disabled_rounded,
                  color: Colors.red[400]),
              label: Text('Disconnect',
                  style: TextStyle(color: Colors.red[400], fontSize: 16)),
            ),
          ],

          // ── HELP TEXT ─────────────────────────────────────────
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.info_outline_rounded,
                      color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  Text('Supported Printers',
                      style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 8),
                const Text(
                  '• Xprinter XP-58 / XP-80 (BLE)\n'
                  '• GOOJPRT PT-180 / PT-200\n'
                  '• MUNBYN ITPP941 (BLE model)\n'
                  '• Rongta RPP02N\n\n'
                  'For Classic Bluetooth SPP printers,\n'
                  'use the "bluetooth_print" package instead.\n\n'
                  'Paper roll: 58mm or 80mm thermal',
                  style: TextStyle(
                      fontSize: 13, height: 1.5, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _connectTo(String deviceId) async {
    final printer = ref.read(thermalPrinterProvider);
    final ok = await printer.connect(deviceId);
    if (mounted) {
      if (ok) {
        showSuccess(context, 'Printer connected! 🖨️');
      } else {
        showError(context, printer.errorMessage ?? 'Connection failed');
      }
    }
  }
}

// ── STATUS CARD ───────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  final ThermalPrinterService printer;
  const _StatusCard({required this.printer});

  @override
  Widget build(BuildContext context) {
    final (icon, color, label, sublabel) = switch (printer.status) {
      PrinterStatus.connected => (
          Icons.print_rounded,
          Colors.green[700]!,
          'Connected / जुड़ा हुआ',
          printer.connectedDeviceName ?? 'Unknown printer',
        ),
      PrinterStatus.connecting => (
          Icons.bluetooth_searching_rounded,
          Colors.blue[700]!,
          'Connecting...',
          'Please wait',
        ),
      PrinterStatus.scanning => (
          Icons.bluetooth_searching_rounded,
          Colors.blue[700]!,
          'Scanning... / खोज रहे हैं',
          'Looking for printers nearby',
        ),
      PrinterStatus.printing => (
          Icons.print_rounded,
          Colors.orange[700]!,
          'Printing... / प्रिंट हो रहा है',
          'Please wait',
        ),
      PrinterStatus.error => (
          Icons.error_rounded,
          Colors.red[700]!,
          'Error / त्रुटि',
          printer.errorMessage ?? 'Unknown error',
        ),
      PrinterStatus.disconnected => (
          Icons.print_disabled_rounded,
          Colors.grey[600]!,
          'Not connected / नहीं जुड़ा',
          'Scan to find printers',
        ),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold, color: color)),
              Text(sublabel,
                  style:
                      TextStyle(fontSize: 13, color: color.withOpacity(0.8))),
            ],
          ),
        ],
      ),
    );
  }
}

// ── DEVICE TILE ───────────────────────────────────────────────────────

class _DeviceTile extends StatelessWidget {
  final PrinterDevice device;
  final bool isConnected;
  final bool isConnecting;
  final VoidCallback onTap;

  const _DeviceTile({
    required this.device,
    required this.isConnected,
    required this.isConnecting,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          Icons.print_rounded,
          color: isConnected ? Colors.green[700] : AppTheme.primary,
          size: 28,
        ),
        title: Text(device.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        subtitle: Text('Signal: ${device.rssi} dBm',
            style: const TextStyle(fontSize: 13)),
        trailing: isConnected
            ? const Icon(Icons.check_circle_rounded,
                color: Colors.green, size: 28)
            : isConnecting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                    ),
                    child: const Text('Connect',
                        style: TextStyle(color: Colors.white)),
                  ),
      ),
    );
  }
}
