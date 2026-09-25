import 'package:equatable/equatable.dart';

class BusinessInfo extends Equatable {
  final String id;
  final String businessName;
  final String? address;
  final String? phone;
  final String? email;
  final String? logoUrl;
  final String? qrisUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isTaxEnabled;
  final double taxRate;
  final String taxName;
  final bool isServiceChargeEnabled;
  final double serviceChargeRate;
  final bool isPriceInclusiveTax;
  final String subscriptionTier;
  final DateTime? subscriptionExpiresAt;
  final String? subscriptionPlan;

  const BusinessInfo({
    required this.id,
    required this.businessName,
    this.address,
    this.phone,
    this.email,
    this.logoUrl,
    this.qrisUrl,
    required this.createdAt,
    required this.updatedAt,
    this.isTaxEnabled = false,
    this.taxRate = 0.0,
    this.taxName = 'Pajak',
    this.isServiceChargeEnabled = false,
    this.serviceChargeRate = 0.0,
    this.isPriceInclusiveTax = false,
    this.subscriptionTier = 'free',
    this.subscriptionExpiresAt,
    this.subscriptionPlan,
  });

  /// True if the business has an active Pro subscription
  bool get isPro {
    if (subscriptionTier.toLowerCase() != 'pro') return false;
    if (subscriptionExpiresAt == null) return false;
    return subscriptionExpiresAt!.isAfter(DateTime.now());
  }

  /// True if the business is on the free tier
  bool get isFree => !isPro;

  /// Remaining days of Pro subscription
  int get remainingProDays {
    if (!isPro || subscriptionExpiresAt == null) return 0;
    final diff = subscriptionExpiresAt!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff + 1;
  }

  BusinessInfo copyWith({
    String? id,
    String? businessName,
    String? address,
    String? phone,
    String? email,
    String? logoUrl,
    String? qrisUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isTaxEnabled,
    double? taxRate,
    String? taxName,
    bool? isServiceChargeEnabled,
    double? serviceChargeRate,
    bool? isPriceInclusiveTax,
    String? subscriptionTier,
    DateTime? subscriptionExpiresAt,
    String? subscriptionPlan,
  }) {
    return BusinessInfo(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      logoUrl: logoUrl ?? this.logoUrl,
      qrisUrl: qrisUrl ?? this.qrisUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isTaxEnabled: isTaxEnabled ?? this.isTaxEnabled,
      taxRate: taxRate ?? this.taxRate,
      taxName: taxName ?? this.taxName,
      isServiceChargeEnabled:
          isServiceChargeEnabled ?? this.isServiceChargeEnabled,
      serviceChargeRate: serviceChargeRate ?? this.serviceChargeRate,
      isPriceInclusiveTax: isPriceInclusiveTax ?? this.isPriceInclusiveTax,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      subscriptionExpiresAt:
          subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
    );
  }

  @override
  List<Object?> get props => [
    id,
    businessName,
    address,
    phone,
    email,
    logoUrl,
    qrisUrl,
    createdAt,
    updatedAt,
    isTaxEnabled,
    taxRate,
    taxName,
    isServiceChargeEnabled,
    serviceChargeRate,
    isPriceInclusiveTax,
    subscriptionTier,
    subscriptionExpiresAt,
    subscriptionPlan,
  ];
}
