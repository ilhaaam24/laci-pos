import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/promo_entity.dart';

class PromoModel extends PromoEntity {
  const PromoModel({
    required super.id,
    required super.name,
    required super.type,
    required super.value,
    super.minPurchase = 0,
    super.isActive = true,
    super.startDate,
    super.endDate,
    super.businessId,
  });

  factory PromoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PromoModel(
      id: doc.id,
      name: data['name'] ?? '',
      type: PromoType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => PromoType.fixed,
      ),
      value: (data['value'] ?? 0).toDouble(),
      minPurchase: (data['minPurchase'] ?? 0).toDouble(),
      isActive: data['isActive'] ?? true,
      startDate: data['startDate'] != null
          ? (data['startDate'] as Timestamp).toDate()
          : null,
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      businessId: data['businessId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'type': type.name,
      'value': value,
      'minPurchase': minPurchase,
      'isActive': isActive,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'businessId': businessId,
    };
  }

  factory PromoModel.fromEntity(PromoEntity entity) {
    return PromoModel(
      id: entity.id,
      name: entity.name,
      type: entity.type,
      value: entity.value,
      minPurchase: entity.minPurchase,
      isActive: entity.isActive,
      startDate: entity.startDate,
      endDate: entity.endDate,
      businessId: entity.businessId,
    );
  }

  PromoModel copyWith({
    String? id,
    String? name,
    PromoType? type,
    double? value,
    double? minPurchase,
    bool? isActive,
    DateTime? startDate,
    DateTime? endDate,
    String? businessId,
  }) {
    return PromoModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      value: value ?? this.value,
      minPurchase: minPurchase ?? this.minPurchase,
      isActive: isActive ?? this.isActive,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      businessId: businessId ?? this.businessId,
    );
  }
}
