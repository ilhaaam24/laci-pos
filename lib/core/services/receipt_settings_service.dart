import 'package:shared_preferences/shared_preferences.dart';

/// Configuration entity for custom receipt display and formatting.
class ReceiptConfig {
  final bool showLogo;
  final String? customLogoPath;
  final bool showWatermark;
  final String headerMessage;
  final String footerMessage;
  final String footerNote;
  final String socialMediaOrWifi;
  final bool showAddress;
  final bool showPhone;
  final bool showCashierName;
  final bool showCustomerName;
  final bool showTableNumber;
  final bool showItemNotes;

  const ReceiptConfig({
    this.showLogo = true,
    this.customLogoPath,
    this.showWatermark = true,
    this.headerMessage = '',
    this.footerMessage = 'TERIMA KASIH TELAH BERBELANJA!',
    this.footerNote = 'Simpan struk digital ini sebagai bukti transaksi yang sah.',
    this.socialMediaOrWifi = '',
    this.showAddress = true,
    this.showPhone = true,
    this.showCashierName = true,
    this.showCustomerName = true,
    this.showTableNumber = true,
    this.showItemNotes = true,
  });

  ReceiptConfig copyWith({
    bool? showLogo,
    String? customLogoPath,
    bool? showWatermark,
    String? headerMessage,
    String? footerMessage,
    String? footerNote,
    String? socialMediaOrWifi,
    bool? showAddress,
    bool? showPhone,
    bool? showCashierName,
    bool? showCustomerName,
    bool? showTableNumber,
    bool? showItemNotes,
  }) {
    return ReceiptConfig(
      showLogo: showLogo ?? this.showLogo,
      customLogoPath: customLogoPath ?? this.customLogoPath,
      showWatermark: showWatermark ?? this.showWatermark,
      headerMessage: headerMessage ?? this.headerMessage,
      footerMessage: footerMessage ?? this.footerMessage,
      footerNote: footerNote ?? this.footerNote,
      socialMediaOrWifi: socialMediaOrWifi ?? this.socialMediaOrWifi,
      showAddress: showAddress ?? this.showAddress,
      showPhone: showPhone ?? this.showPhone,
      showCashierName: showCashierName ?? this.showCashierName,
      showCustomerName: showCustomerName ?? this.showCustomerName,
      showTableNumber: showTableNumber ?? this.showTableNumber,
      showItemNotes: showItemNotes ?? this.showItemNotes,
    );
  }
}

/// Service managing persistent configuration for digital and thermal receipts.
class ReceiptSettingsService {
  static final ReceiptSettingsService _instance =
      ReceiptSettingsService._internal();

  factory ReceiptSettingsService() => _instance;

  ReceiptSettingsService._internal();

  static const String _kShowLogo = 'pref_receipt_show_logo';
  static const String _kCustomLogoPath = 'pref_receipt_custom_logo_path';
  static const String _kShowWatermark = 'pref_receipt_show_watermark';
  static const String _kHeaderMessage = 'pref_receipt_header_msg';
  static const String _kFooterMessage = 'pref_receipt_footer_msg';
  static const String _kFooterNote = 'pref_receipt_footer_note';
  static const String _kSocialMediaOrWifi = 'pref_receipt_social_wifi';
  static const String _kShowAddress = 'pref_receipt_show_address';
  static const String _kShowPhone = 'pref_receipt_show_phone';
  static const String _kShowCashier = 'pref_receipt_show_cashier';
  static const String _kShowCustomer = 'pref_receipt_show_customer';
  static const String _kShowTable = 'pref_receipt_show_table';
  static const String _kShowNotes = 'pref_receipt_show_notes';

  ReceiptConfig _config = const ReceiptConfig();
  ReceiptConfig get config => _config;

  /// Loads configuration from SharedPreferences.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _config = ReceiptConfig(
        showLogo: prefs.getBool(_kShowLogo) ?? true,
        customLogoPath: prefs.getString(_kCustomLogoPath),
        showWatermark: prefs.getBool(_kShowWatermark) ?? true,
        headerMessage: prefs.getString(_kHeaderMessage) ?? '',
        footerMessage: prefs.getString(_kFooterMessage) ??
            'TERIMA KASIH TELAH BERBELANJA!',
        footerNote: prefs.getString(_kFooterNote) ??
            'Simpan struk digital ini sebagai bukti transaksi yang sah.',
        socialMediaOrWifi: prefs.getString(_kSocialMediaOrWifi) ?? '',
        showAddress: prefs.getBool(_kShowAddress) ?? true,
        showPhone: prefs.getBool(_kShowPhone) ?? true,
        showCashierName: prefs.getBool(_kShowCashier) ?? true,
        showCustomerName: prefs.getBool(_kShowCustomer) ?? true,
        showTableNumber: prefs.getBool(_kShowTable) ?? true,
        showItemNotes: prefs.getBool(_kShowNotes) ?? true,
      );
    } catch (_) {}
  }

  /// Persists [newConfig] to SharedPreferences and updates in-memory config.
  Future<void> saveConfig(ReceiptConfig newConfig) async {
    _config = newConfig;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kShowLogo, newConfig.showLogo);
      if (newConfig.customLogoPath != null &&
          newConfig.customLogoPath!.isNotEmpty) {
        await prefs.setString(_kCustomLogoPath, newConfig.customLogoPath!);
      } else {
        await prefs.remove(_kCustomLogoPath);
      }
      await prefs.setBool(_kShowWatermark, newConfig.showWatermark);
      await prefs.setString(_kHeaderMessage, newConfig.headerMessage);
      await prefs.setString(_kFooterMessage, newConfig.footerMessage);
      await prefs.setString(_kFooterNote, newConfig.footerNote);
      await prefs.setString(
          _kSocialMediaOrWifi, newConfig.socialMediaOrWifi);
      await prefs.setBool(_kShowAddress, newConfig.showAddress);
      await prefs.setBool(_kShowPhone, newConfig.showPhone);
      await prefs.setBool(_kShowCashier, newConfig.showCashierName);
      await prefs.setBool(_kShowCustomer, newConfig.showCustomerName);
      await prefs.setBool(_kShowTable, newConfig.showTableNumber);
      await prefs.setBool(_kShowNotes, newConfig.showItemNotes);
    } catch (_) {}
  }

  /// Resets configuration to default settings.
  Future<void> resetToDefault() async {
    await saveConfig(const ReceiptConfig());
  }
}
