import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agri_ledger_app/core/theme/app_theme.dart';
import 'package:agri_ledger_app/features/auth/screens/pin_screen.dart';
import 'package:agri_ledger_app/features/home/screens/home_screen.dart';
import 'package:agri_ledger_app/features/home/widgets/today_summary_card.dart';
import 'package:agri_ledger_app/features/transactions/screens/entry_screen.dart';
import 'package:agri_ledger_app/features/parties/screens/parties_screen.dart';
import 'package:agri_ledger_app/features/bags/screens/bags_screen.dart';
import 'package:agri_ledger_app/features/settings/screens/settings_screen.dart';
import 'package:agri_ledger_app/features/employees/widgets/workforce_dashboard_card.dart';

void main() {
  const devices = [
    ('iPhone SE (Small Phone)', Size(320, 568)),
    ('Android Compact Phone', Size(360, 640)),
    ('Standard Mobile (iPhone 14/15)', Size(390, 844)),
    ('Large Flagship (Pixel/Galaxy)', Size(412, 915)),
    ('iPad Portrait (Tablet)', Size(768, 1024)),
    ('iPad Landscape (Tablet)', Size(1024, 768)),
    ('Desktop / Web', Size(1280, 800)),
  ];

  group('Multi-Device Responsive Layout Verification', () {
    for (final (deviceName, size) in devices) {
      testWidgets('PinScreen renders without overflow on $deviceName ($size)',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: const ProviderScope(child: PinScreen()),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
      });

      testWidgets(
          'WorkforceDashboardCard renders without overflow on $deviceName ($size)',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(
              body: ProviderScope(child: WorkforceDashboardCard()),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
      });

      testWidgets(
          'TodaySummaryCard renders without overflow on $deviceName ($size)',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(
              body: ProviderScope(child: TodaySummaryCard()),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
      });

      testWidgets('HomeScreen renders without overflow on $deviceName ($size)',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: const ProviderScope(child: HomeScreen()),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
      });

      testWidgets('EntryScreen renders without overflow on $deviceName ($size)',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: const ProviderScope(child: EntryScreen()),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
      });

      testWidgets(
          'PartiesScreen renders without overflow on $deviceName ($size)',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: const ProviderScope(child: Scaffold(body: PartiesScreen())),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
      });

      testWidgets('BagsScreen renders without overflow on $deviceName ($size)',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: const ProviderScope(child: Scaffold(body: BagsScreen())),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
      });

      testWidgets(
          'SettingsScreen renders without overflow on $deviceName ($size)',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: const ProviderScope(child: Scaffold(body: SettingsScreen())),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
      });
    }
  });
}
