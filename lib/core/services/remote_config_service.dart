import 'dart:developer';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class RemoteConfigKeys {
  static const String androidForceUpdate = 'android_force_update';
  static const String androidMinVersion = 'android_min_version';
  static const String playstoreUrl = 'playstore_url';

  static const String iosForceUpdate = 'ios_force_update';
  static const String iosMinVersion = 'ios_min_version';
  static const String appstoreUrl = 'appstore_url';
}

enum AppUpdateStatus { none, optional, forced }

class AppUpdateCheckResult {
  final AppUpdateStatus status;
  final int currentBuildNumber;
  final int minVersion;
  final String storeUrl;

  const AppUpdateCheckResult({
    required this.status,
    required this.currentBuildNumber,
    required this.minVersion,
    required this.storeUrl,
  });

  bool get hasUpdate => status != AppUpdateStatus.none;
  bool get isForced => status == AppUpdateStatus.forced;
  bool get isOptional => status == AppUpdateStatus.optional;
}

class RemoteConfigService {
  FirebaseRemoteConfig? _remoteConfig;
  bool _initialized = false;

  static const String defaultPlayStoreUrl =
      'https://play.google.com/store/apps/details?id=com.ilhaaam24.lacipos&pcampaignid=web_share';

  RemoteConfigService({FirebaseRemoteConfig? remoteConfig})
      : _remoteConfig = remoteConfig;

  Future<void> init() async {
    if (_initialized) return;

    try {
      final rc = _remoteConfig ?? FirebaseRemoteConfig.instance;
      _remoteConfig = rc;

      await rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kDebugMode
              ? const Duration(minutes: 1)
              : const Duration(hours: 1),
        ),
      );

      await rc.setDefaults(const <String, dynamic>{
        RemoteConfigKeys.androidForceUpdate: false,
        RemoteConfigKeys.androidMinVersion: 1,
        RemoteConfigKeys.playstoreUrl: defaultPlayStoreUrl,
        RemoteConfigKeys.iosForceUpdate: false,
        RemoteConfigKeys.iosMinVersion: 1,
        RemoteConfigKeys.appstoreUrl: '',
      });

      final updated = await rc.fetchAndActivate();
      _initialized = true;
      log(
        'RemoteConfigService initialized (updated: $updated, '
        'android_min: $androidMinVersion, android_force: $androidForceUpdate, '
        'ios_min: $iosMinVersion, ios_force: $iosForceUpdate)',
      );
    } catch (e) {
      log('RemoteConfigService init warning: $e');
    }
  }

  bool get androidForceUpdate =>
      _remoteConfig?.getBool(RemoteConfigKeys.androidForceUpdate) ?? false;

  int get androidMinVersion =>
      _remoteConfig?.getInt(RemoteConfigKeys.androidMinVersion) ?? 1;

  String get playstoreUrl => _sanitizeUrl(
        _remoteConfig?.getString(RemoteConfigKeys.playstoreUrl) ??
            defaultPlayStoreUrl,
      );

  bool get iosForceUpdate =>
      _remoteConfig?.getBool(RemoteConfigKeys.iosForceUpdate) ?? false;

  int get iosMinVersion =>
      _remoteConfig?.getInt(RemoteConfigKeys.iosMinVersion) ?? 1;

  String get appstoreUrl => _sanitizeUrl(
        _remoteConfig?.getString(RemoteConfigKeys.appstoreUrl) ?? '',
      );

  static String _sanitizeUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') {
      return '';
    }
    return trimmed;
  }

  /// Evaluates whether an app update is required or optional.
  static AppUpdateCheckResult evaluateUpdate({
    required TargetPlatform platform,
    required int currentBuildNumber,
    required int androidMinVersion,
    required bool androidForceUpdate,
    required String playstoreUrl,
    required int iosMinVersion,
    required bool iosForceUpdate,
    required String appstoreUrl,
  }) {
    int minVersion = 1;
    bool forceUpdate = false;
    String storeUrl = '';

    if (platform == TargetPlatform.android) {
      minVersion = androidMinVersion;
      forceUpdate = androidForceUpdate;
      storeUrl = _sanitizeUrl(playstoreUrl);
    } else if (platform == TargetPlatform.iOS) {
      minVersion = iosMinVersion;
      forceUpdate = iosForceUpdate;
      storeUrl = _sanitizeUrl(appstoreUrl);
    } else {
      return AppUpdateCheckResult(
        status: AppUpdateStatus.none,
        currentBuildNumber: currentBuildNumber,
        minVersion: 1,
        storeUrl: '',
      );
    }

    // Do not lock out or prompt update if store URL is unavailable/null
    if (currentBuildNumber < minVersion && storeUrl.isNotEmpty) {
      return AppUpdateCheckResult(
        status: forceUpdate ? AppUpdateStatus.forced : AppUpdateStatus.optional,
        currentBuildNumber: currentBuildNumber,
        minVersion: minVersion,
        storeUrl: storeUrl,
      );
    }

    return AppUpdateCheckResult(
      status: AppUpdateStatus.none,
      currentBuildNumber: currentBuildNumber,
      minVersion: minVersion,
      storeUrl: storeUrl,
    );
  }

  Future<AppUpdateCheckResult> checkForUpdate({
    TargetPlatform? platformOverride,
    int? buildNumberOverride,
  }) async {
    int currentBuildNumber = buildNumberOverride ?? 1;
    if (buildNumberOverride == null) {
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 1;
      } catch (e) {
        log('RemoteConfigService PackageInfo error: $e');
      }
    }

    return evaluateUpdate(
      platform: platformOverride ?? defaultTargetPlatform,
      currentBuildNumber: currentBuildNumber,
      androidMinVersion: androidMinVersion,
      androidForceUpdate: androidForceUpdate,
      playstoreUrl: playstoreUrl,
      iosMinVersion: iosMinVersion,
      iosForceUpdate: iosForceUpdate,
      appstoreUrl: appstoreUrl,
    );
  }
}

