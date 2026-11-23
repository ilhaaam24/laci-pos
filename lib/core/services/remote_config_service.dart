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
  final String currentVersion;
  final int currentBuildNumber;
  final String minVersion;
  final String storeUrl;

  const AppUpdateCheckResult({
    required this.status,
    required this.currentVersion,
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
        RemoteConfigKeys.androidMinVersion: '1.0.0',
        RemoteConfigKeys.playstoreUrl: defaultPlayStoreUrl,
        RemoteConfigKeys.iosForceUpdate: false,
        RemoteConfigKeys.iosMinVersion: '1.0.0',
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

  String get androidMinVersion => _sanitizeVersion(
    _remoteConfig?.getString(RemoteConfigKeys.androidMinVersion) ?? '1.0.0',
  );

  String get playstoreUrl => _sanitizeUrl(
    _remoteConfig?.getString(RemoteConfigKeys.playstoreUrl) ??
        defaultPlayStoreUrl,
  );

  bool get iosForceUpdate =>
      _remoteConfig?.getBool(RemoteConfigKeys.iosForceUpdate) ?? false;

  String get iosMinVersion => _sanitizeVersion(
    _remoteConfig?.getString(RemoteConfigKeys.iosMinVersion) ?? '1.0.0',
  );

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

  static String _sanitizeVersion(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') {
      return '1.0.0';
    }
    return trimmed;
  }

  /// Compares two semantic version strings (e.g. "1.0.1" vs "1.0.2").
  /// Returns negative if [a] < [b], 0 if equal, positive if [a] > [b].
  static int compareSemanticVersions(String a, String b) {
    final cleanA = a.split('+').first.split('-').first.trim();
    final cleanB = b.split('+').first.split('-').first.trim();

    final partsA = cleanA.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final partsB = cleanB.split('.').map((p) => int.tryParse(p) ?? 0).toList();

    final maxLen = partsA.length > partsB.length
        ? partsA.length
        : partsB.length;
    for (var i = 0; i < maxLen; i++) {
      final numA = i < partsA.length ? partsA[i] : 0;
      final numB = i < partsB.length ? partsB[i] : 0;
      if (numA != numB) return numA.compareTo(numB);
    }
    return 0;
  }

  /// Returns true if the current app version is strictly lower than [minVersion].
  /// Supports both semantic versions (e.g. "1.0.2") and integer build numbers (e.g. "11").
  static bool isOutdated({
    required String currentVersion,
    required int currentBuildNumber,
    required String minVersion,
  }) {
    final cleanMin = minVersion.trim();
    if (cleanMin.isEmpty || cleanMin.toLowerCase() == 'null') {
      return false;
    }

    if (cleanMin.contains('.')) {
      return compareSemanticVersions(currentVersion, cleanMin) < 0;
    }

    final minBuild = int.tryParse(cleanMin);
    if (minBuild == null) return false;
    return currentBuildNumber < minBuild;
  }

  /// Evaluates whether an app update is required or optional.
  static AppUpdateCheckResult evaluateUpdate({
    required TargetPlatform platform,
    required String currentVersion,
    required int currentBuildNumber,
    required String androidMinVersion,
    required bool androidForceUpdate,
    required String playstoreUrl,
    required String iosMinVersion,
    required bool iosForceUpdate,
    required String appstoreUrl,
  }) {
    String minVersion = '1.0.0';
    bool forceUpdate = false;
    String storeUrl = '';

    if (platform == TargetPlatform.android) {
      minVersion = _sanitizeVersion(androidMinVersion);
      forceUpdate = androidForceUpdate;
      storeUrl = _sanitizeUrl(playstoreUrl);
    } else if (platform == TargetPlatform.iOS) {
      minVersion = _sanitizeVersion(iosMinVersion);
      forceUpdate = iosForceUpdate;
      storeUrl = _sanitizeUrl(appstoreUrl);
    } else {
      return AppUpdateCheckResult(
        status: AppUpdateStatus.none,
        currentVersion: currentVersion,
        currentBuildNumber: currentBuildNumber,
        minVersion: '1.0.0',
        storeUrl: '',
      );
    }

    final outdated = isOutdated(
      currentVersion: currentVersion,
      currentBuildNumber: currentBuildNumber,
      minVersion: minVersion,
    );

    // Do not lock out or prompt update if store URL is unavailable/null
    if (outdated && storeUrl.isNotEmpty) {
      return AppUpdateCheckResult(
        status: forceUpdate ? AppUpdateStatus.forced : AppUpdateStatus.optional,
        currentVersion: currentVersion,
        currentBuildNumber: currentBuildNumber,
        minVersion: minVersion,
        storeUrl: storeUrl,
      );
    }

    return AppUpdateCheckResult(
      status: AppUpdateStatus.none,
      currentVersion: currentVersion,
      currentBuildNumber: currentBuildNumber,
      minVersion: minVersion,
      storeUrl: storeUrl,
    );
  }

  Future<AppUpdateCheckResult> checkForUpdate({
    TargetPlatform? platformOverride,
    String? versionOverride,
    int? buildNumberOverride,
  }) async {
    String currentVersion = versionOverride ?? '1.0.0';
    int currentBuildNumber = buildNumberOverride ?? 1;

    if (versionOverride == null || buildNumberOverride == null) {
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        currentVersion = versionOverride ?? packageInfo.version;
        currentBuildNumber =
            buildNumberOverride ?? (int.tryParse(packageInfo.buildNumber) ?? 1);
      } catch (e) {
        log('RemoteConfigService PackageInfo error: $e');
      }
    }

    return evaluateUpdate(
      platform: platformOverride ?? defaultTargetPlatform,
      currentVersion: currentVersion,
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
