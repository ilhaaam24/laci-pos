import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    super.name,
    super.photoUrl,
    super.role,
    super.businessId,
    super.isEmailVerified,
    super.pin,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'],
      photoUrl: data['photoUrl'],
      role: UserRole.fromString(data['role']),
      businessId: data['businessId'],
      pin: data['pin']?.toString(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'role': role.name,
      'businessId': businessId,
      if (pin != null) 'pin': pin,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String?,
      photoUrl: json['photoUrl'] as String?,
      role: UserRole.fromString(json['role'] as String?),
      businessId: json['businessId'] as String?,
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      pin: json['pin']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'role': role.name,
      'businessId': businessId,
      'isEmailVerified': isEmailVerified,
      'pin': pin,
    };
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      name: entity.name,
      photoUrl: entity.photoUrl,
      role: entity.role,
      businessId: entity.businessId,
      isEmailVerified: entity.isEmailVerified,
      pin: entity.pin,
    );
  }

  @override
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    UserRole? role,
    String? businessId,
    bool? isEmailVerified,
    String? pin,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      businessId: businessId ?? this.businessId,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      pin: pin ?? this.pin,
    );
  }
}
