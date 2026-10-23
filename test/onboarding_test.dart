import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:laci/core/services/onboarding_service.dart';
import 'package:laci/presentation/pages/onboarding/onboarding_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('OnboardingService Tests', () {
    test('defaults to false on fresh install', () async {
      final completed = await OnboardingService.hasCompletedOnboarding();
      expect(completed, isFalse);
    });

    test('sets and persists completed state', () async {
      await OnboardingService.setOnboardingCompleted();
      final completed = await OnboardingService.hasCompletedOnboarding();
      expect(completed, isTrue);
    });

    test('resets completed state back to false', () async {
      await OnboardingService.setOnboardingCompleted();
      expect(await OnboardingService.hasCompletedOnboarding(), isTrue);

      await OnboardingService.resetOnboarding();
      expect(await OnboardingService.hasCompletedOnboarding(), isFalse);
    });
  });

  group('OnboardingPage Widget Tests', () {
    Widget buildTestWidget({VoidCallback? onComplete, bool isDark = false}) {
      return MaterialApp(
        theme: isDark ? ThemeData.dark() : ThemeData.light(),
        home: OnboardingPage(onComplete: onComplete),
      );
    }

    testWidgets(
      'renders first slide correctly without overflow on standard mobile (375x812)',
      (tester) async {
        tester.view.physicalSize = const Size(375 * 2, 812 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.reset());

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Lewati'), findsOneWidget);
        expect(find.text('Transaksi Kasir Cepat & Praktis'), findsOneWidget);
        expect(
          find.text(
            'Catat pesanan pelanggan, hitung total otomatis, dan cetak struk via printer Bluetooth dalam hitungan detik.',
          ),
          findsOneWidget,
        );
        expect(find.text('Lanjut'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'renders on narrow mobile (320x568) without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320 * 2, 568 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.reset());

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Lewati'), findsOneWidget);
        expect(find.text('Transaksi Kasir Cepat & Praktis'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'navigates through all 3 sliders when Lanjut is tapped',
      (tester) async {
        tester.view.physicalSize = const Size(390 * 2, 844 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.reset());

        bool completed = false;
        await tester.pumpWidget(
          buildTestWidget(onComplete: () => completed = true),
        );
        await tester.pumpAndSettle();

        // Slide 1
        expect(find.text('Transaksi Kasir Cepat & Praktis'), findsOneWidget);

        // Tap Lanjut -> Slide 2
        await tester.tap(find.text('Lanjut'));
        await tester.pumpAndSettle();
        expect(find.text('Kelola Produk & Pantau Stok'), findsOneWidget);

        // Tap Lanjut -> Slide 3
        await tester.tap(find.text('Lanjut'));
        await tester.pumpAndSettle();
        expect(find.text('Laporan Keuangan & Rekap Shift'), findsOneWidget);
        expect(find.text('Mulai Sekarang'), findsOneWidget);

        // Tap Mulai Sekarang -> invokes onComplete & persists in SharedPreferences
        await tester.tap(find.text('Mulai Sekarang'));
        await tester.pumpAndSettle();
        expect(completed, isTrue);
        expect(await OnboardingService.hasCompletedOnboarding(), isTrue);
      },
    );

    testWidgets(
      'tapping Lewati immediately finishes onboarding',
      (tester) async {
        tester.view.physicalSize = const Size(390 * 2, 844 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.reset());

        bool completed = false;
        await tester.pumpWidget(
          buildTestWidget(onComplete: () => completed = true),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Lewati'));
        await tester.pumpAndSettle();

        expect(completed, isTrue);
        expect(await OnboardingService.hasCompletedOnboarding(), isTrue);
      },
    );

    testWidgets('renders in dark mode without error', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.reset());

      await tester.pumpWidget(buildTestWidget(isDark: true));
      await tester.pumpAndSettle();

      expect(find.text('Transaksi Kasir Cepat & Praktis'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
