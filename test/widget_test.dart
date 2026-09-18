import 'package:flutter_test/flutter_test.dart';
import 'package:laci/domain/entities/user_entity.dart';

void main() {
  test('UserEntity supports email verification and copyWith', () {
    const user = UserEntity(
      id: 'test_123',
      email: 'test@example.com',
      name: 'Test User',
      role: UserRole.owner,
      isEmailVerified: false,
    );

    expect(user.isEmailVerified, isFalse);
    expect(user.role, UserRole.owner);

    final verifiedUser = user.copyWith(isEmailVerified: true);
    expect(verifiedUser.isEmailVerified, isTrue);
    expect(verifiedUser.id, user.id);
  });
}
