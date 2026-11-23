import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laci/core/services/remote_config_service.dart';
import 'package:laci/presentation/widgets/app_update_dialog.dart';

void main() {
  group('RemoteConfigService.evaluateUpdate Unit Tests', () {
    const playStoreUrl =
        'https://play.google.com/store/apps/details?id=com.ilhaaam24.lacipos&pcampaignid=web_share';
    const appStoreUrl = 'https://apps.apple.com/app/id123456789';

    test('returns none when Android semantic version meets or exceeds minVersion (e.g. 1.0.1 >= 1.0.0)', () {
      final result = RemoteConfigService.evaluateUpdate(
        platform: TargetPlatform.android,
        currentVersion: '1.0.1',
        currentBuildNumber: 10,
        androidMinVersion: '1.0.0',
        androidForceUpdate: true,
        playstoreUrl: playStoreUrl,
        iosMinVersion: '1.0.0',
        iosForceUpdate: false,
        appstoreUrl: 'null',
      );

      expect(result.status, AppUpdateStatus.none);
      expect(result.hasUpdate, isFalse);
    });

    test('returns optional when Android semantic version is below minVersion and force is false', () {
      final result = RemoteConfigService.evaluateUpdate(
        platform: TargetPlatform.android,
        currentVersion: '1.0.1',
        currentBuildNumber: 10,
        androidMinVersion: '1.0.2',
        androidForceUpdate: false,
        playstoreUrl: playStoreUrl,
        iosMinVersion: '1.0.0',
        iosForceUpdate: false,
        appstoreUrl: 'null',
      );

      expect(result.status, AppUpdateStatus.optional);
      expect(result.hasUpdate, isTrue);
      expect(result.isOptional, isTrue);
      expect(result.isForced, isFalse);
      expect(result.storeUrl, playStoreUrl);
    });

    test('returns forced when Android semantic version is below minVersion (1.2.0 < 1.10.0) and force is true', () {
      final result = RemoteConfigService.evaluateUpdate(
        platform: TargetPlatform.android,
        currentVersion: '1.2.0',
        currentBuildNumber: 10,
        androidMinVersion: '1.10.0',
        androidForceUpdate: true,
        playstoreUrl: playStoreUrl,
        iosMinVersion: '1.0.0',
        iosForceUpdate: false,
        appstoreUrl: 'null',
      );

      expect(result.status, AppUpdateStatus.forced);
      expect(result.isForced, isTrue);
      expect(result.storeUrl, playStoreUrl);
    });

    test('also supports integer build number minVersion (e.g. "12")', () {
      final result = RemoteConfigService.evaluateUpdate(
        platform: TargetPlatform.android,
        currentVersion: '1.0.1',
        currentBuildNumber: 10,
        androidMinVersion: '12',
        androidForceUpdate: true,
        playstoreUrl: playStoreUrl,
        iosMinVersion: '1',
        iosForceUpdate: false,
        appstoreUrl: 'null',
      );

      expect(result.status, AppUpdateStatus.forced);
    });

    test('returns none on iOS when appstore_url is literal "null" or empty', () {
      final result = RemoteConfigService.evaluateUpdate(
        platform: TargetPlatform.iOS,
        currentVersion: '1.0.0',
        currentBuildNumber: 1,
        androidMinVersion: '1.0.0',
        androidForceUpdate: false,
        playstoreUrl: playStoreUrl,
        iosMinVersion: '2.0.0',
        iosForceUpdate: true,
        appstoreUrl: 'null',
      );

      expect(result.status, AppUpdateStatus.none);
      expect(result.storeUrl, isEmpty);
    });

    test('returns forced on iOS when appstore_url is valid and iosForceUpdate is true', () {
      final result = RemoteConfigService.evaluateUpdate(
        platform: TargetPlatform.iOS,
        currentVersion: '1.0.0',
        currentBuildNumber: 2,
        androidMinVersion: '1.0.0',
        androidForceUpdate: false,
        playstoreUrl: playStoreUrl,
        iosMinVersion: '1.1.0',
        iosForceUpdate: true,
        appstoreUrl: appStoreUrl,
      );

      expect(result.status, AppUpdateStatus.forced);
      expect(result.isForced, isTrue);
      expect(result.storeUrl, appStoreUrl);
    });

    test('returns none on desktop platforms', () {
      final result = RemoteConfigService.evaluateUpdate(
        platform: TargetPlatform.macOS,
        currentVersion: '1.0.0',
        currentBuildNumber: 1,
        androidMinVersion: '9.9.9',
        androidForceUpdate: true,
        playstoreUrl: playStoreUrl,
        iosMinVersion: '9.9.9',
        iosForceUpdate: true,
        appstoreUrl: appStoreUrl,
      );

      expect(result.status, AppUpdateStatus.none);
    });
  });

  group('AppUpdateDialog Widget Tests', () {
    testWidgets('renders forced update dialog without Nanti Saja button', (tester) async {
      bool updateTapped = false;
      const forcedResult = AppUpdateCheckResult(
        status: AppUpdateStatus.forced,
        currentVersion: '1.0.1',
        currentBuildNumber: 10,
        minVersion: '1.0.2',
        storeUrl: RemoteConfigService.defaultPlayStoreUrl,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppUpdateDialog(
              result: forcedResult,
              onUpdateTap: () => updateTapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pembaruan Diperlukan'), findsOneWidget);
      expect(find.byKey(const ValueKey('update_now_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('update_later_button')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('update_now_button')));
      await tester.pump();
      expect(updateTapped, isTrue);
    });

    testWidgets('renders optional update dialog and dismisses on Nanti Saja tap', (tester) async {
      const optionalResult = AppUpdateCheckResult(
        status: AppUpdateStatus.optional,
        currentVersion: '1.0.1',
        currentBuildNumber: 10,
        minVersion: '1.0.2',
        storeUrl: RemoteConfigService.defaultPlayStoreUrl,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => AppUpdateDialog.show(context, optionalResult),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Pembaruan Tersedia'), findsOneWidget);
      expect(find.byKey(const ValueKey('update_now_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('update_later_button')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('update_later_button')));
      await tester.pumpAndSettle();

      expect(find.text('Pembaruan Tersedia'), findsNothing);
    });

    testWidgets('renders cleanly in dark mode on narrow 320dp screen without overflow', (tester) async {
      tester.view.physicalSize = const Size(320 * 2, 568 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.reset());

      const optionalResult = AppUpdateCheckResult(
        status: AppUpdateStatus.optional,
        currentVersion: '1.0.1',
        currentBuildNumber: 10,
        minVersion: '1.0.2',
        storeUrl: RemoteConfigService.defaultPlayStoreUrl,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: AppUpdateDialog(result: optionalResult),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pembaruan Tersedia'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
