import 'package:equatable/equatable.dart';

enum UserRole {
  admin,
  manager,
  kasir,
  owner;

  static UserRole fromString(String? role) {
    switch (role?.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'manager':
        return UserRole.manager;
      case 'kasir':
        return UserRole.kasir;
      case 'owner':
        return UserRole.owner;
      default:
        return UserRole.kasir; // Default role
    }
  }

  String get name => toString().split('.').last;
}

extension UserRoleX on UserRole {
  bool get isAdmin => this == UserRole.admin;
  bool get isManager => this == UserRole.manager;
  bool get isKasir => this == UserRole.kasir;
  bool get isOwner => this == UserRole.owner;

  bool get canAccessPOS => isAdmin || isManager || isKasir || isOwner;
  bool get canAccessReports => isAdmin || isManager || isOwner;
  bool get canManageInventory => isAdmin || isManager || isOwner;
  bool get canAccessSettings => isAdmin || isManager || isKasir || isOwner;
  bool get canManageUsers => isAdmin || isOwner;
}

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String? name;
  final String? photoUrl;
  final UserRole role;
  final String? businessId;
  final bool isEmailVerified;
  final String? pin;

  const UserEntity({
    required this.id,
    required this.email,
    this.name,
    this.photoUrl,
    this.role = UserRole.owner,
    this.businessId,
    this.isEmailVerified = false,
    this.pin,
  });

  UserEntity copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    UserRole? role,
    String? businessId,
    bool? isEmailVerified,
    String? pin,
  }) {
    return UserEntity(
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

  @override
  List<Object?> get props => [
    id,
    email,
    name,
    photoUrl,
    role,
    businessId,
    isEmailVerified,
    pin,
  ];
}
