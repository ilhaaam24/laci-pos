import 'package:equatable/equatable.dart';

enum PromoType { fixed, percentage }

class PromoEntity extends Equatable {
  final String id;
  final String name;
  final PromoType type;
  final double value;
  final double minPurchase;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? businessId;

  const PromoEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    this.minPurchase = 0,
    this.isActive = true,
    this.startDate,
    this.endDate,
    this.businessId,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    value,
    minPurchase,
    isActive,
    startDate,
    endDate,
    businessId,
  ];
}
