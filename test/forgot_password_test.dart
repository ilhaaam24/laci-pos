import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laci/data/datasources/firebase/auth_firebase_datasource.dart';
import 'package:laci/data/datasources/firebase/user_firebase_datasource.dart';
import 'package:laci/data/models/user_model.dart';
import 'package:laci/data/repositories/auth_repository_impl.dart';
import 'package:laci/domain/entities/user_entity.dart';
import 'package:laci/domain/repositories/auth_repository.dart';
import 'package:laci/presentation/pages/auth/forgot_password_page.dart';

class MockAuthRepository implements AuthRepository {
  Either<String, void>? resetResult;
  String? lastRequestedEmail;
  int resetCallCount = 0;

  @override
  Future<Either<String, void>> sendPasswordResetEmail({
    required String email,
  }) async {
    resetCallCount++;
    lastRequestedEmail = email;
    return resetResult ?? const Right(null);
  }

  @override
  Future<Either<String, bool>> checkEmailVerified() async => const Right(true);

  @override
  Future<Either<String, void>> deleteAccount() async => const Right(null);

  @override
  Future<Either<String, UserEntity?>> getCurrentUser() async => const Right(null);

  @override
  Future<Either<String, void>> sendEmailVerification() async => const Right(null);

  @override
  Future<Either<String, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Future<Either<String, UserEntity>> signInWithGoogle() async =>
      throw UnimplementedError();

  @override
  Future<Either<String, void>> signOut() async => const Right(null);

  @override
  Future<Either<String, UserEntity>> signUpWithEmail({
    required String email,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Stream<UserEntity?> get authStateChanges => const Stream.empty();
}

class MockUser extends Fake implements User {
  @override
  final String uid;
  @override
  final String? email;
  @override
  final String? displayName;
  @override
  final String? photoURL;
  @override
  final bool emailVerified;

  MockUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.emailVerified = true,
  });
}

class MockUserCredential extends Fake implements UserCredential {
  @override
  final User? user;

  MockUserCredential({this.user});
}

class FakeAuthFirebaseDataSource implements AuthFirebaseDataSource {
  String? lastResetEmail;
  FirebaseAuthException? firebaseAuthExceptionToThrow;
  Exception? genericExceptionToThrow;
  UserCredential? credentialToReturn;

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    lastResetEmail = email;
    if (firebaseAuthExceptionToThrow != null) {
      throw firebaseAuthExceptionToThrow!;
    }
    if (genericExceptionToThrow != null) {
      throw genericExceptionToThrow!;
    }
  }

  @override
  Stream<User?> get authStateChanges => const Stream.empty();

  @override
  Future<bool> checkEmailVerified() async => true;

  @override
  Future<void> deleteAccount() async {}

  @override
  User? getCurrentUser() => null;

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return credentialToReturn ??
        MockUserCredential(user: MockUser(uid: 'uid_email', email: email));
  }

  @override
  Future<UserCredential> signInWithGoogle() => throw UnimplementedError();

  @override
  Future<void> signOut() async {}

  @override
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) => throw UnimplementedError();
}

class FakeUserFirebaseDataSource implements UserFirebaseDataSource {
  final Map<String, UserModel> usersByUid = {};
  final List<UserModel> createdProfiles = [];

  @override
  Future<void> createUserProfile(UserModel user) async {
    usersByUid[user.id] = user;
    createdProfiles.add(user);
  }

  @override
  Future<void> deleteUser(String uid) async {
    usersByUid.remove(uid);
  }

  @override
  Future<UserModel?> getUserByEmail(String email) async {
    final list = await getAllUsersByEmail(email);
    return list.isNotEmpty ? list.first : null;
  }

  @override
  Future<List<UserModel>> getAllUsersByEmail(String email) async {
    final clean = email.toLowerCase().trim();
    return usersByUid.values
        .where((u) => u.email.toLowerCase().trim() == clean)
        .toList();
  }

  @override
  Future<UserModel?> getUserProfile(String uid) async => usersByUid[uid];

  @override
  Future<List<UserModel>> getUsers() async => usersByUid.values.toList();

  @override
  Future<void> updateUserProfile(UserModel user) async {
    usersByUid[user.id] = user;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
  });

  Widget buildTestWidget({
    String? initialEmail,
    bool isDark = false,
  }) {
    return MaterialApp(
      theme: isDark ? ThemeData.dark() : ThemeData.light(),
      home: ForgotPasswordPage(
        initialEmail: initialEmail,
        authRepository: mockAuthRepository,
      ),
    );
  }

  group('AuthRepositoryImpl sendPasswordResetEmail Unit Tests', () {
    late FakeAuthFirebaseDataSource fakeDataSource;
    late FakeUserFirebaseDataSource fakeUserDataSource;
    late AuthRepositoryImpl authRepository;

    setUp(() {
      fakeDataSource = FakeAuthFirebaseDataSource();
      fakeUserDataSource = FakeUserFirebaseDataSource();
      authRepository = AuthRepositoryImpl(
        dataSource: fakeDataSource,
        userDataSource: fakeUserDataSource,
      );
    });

    test('returns Right(null) when datasource succeeds', () async {
      final result = await authRepository.sendPasswordResetEmail(
        email: 'test@example.com',
      );

      expect(result.isRight(), isTrue);
      expect(fakeDataSource.lastResetEmail, 'test@example.com');
    });

    test('maps user-not-found to user friendly message', () async {
      fakeDataSource.firebaseAuthExceptionToThrow = FirebaseAuthException(
        code: 'user-not-found',
      );

      final result = await authRepository.sendPasswordResetEmail(
        email: 'unknown@example.com',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (err) => expect(err, 'Akun dengan email ini tidak ditemukan.'),
        (_) => fail('Should not succeed'),
      );
    });

    test('maps invalid-email to user friendly message', () async {
      fakeDataSource.firebaseAuthExceptionToThrow = FirebaseAuthException(
        code: 'invalid-email',
      );

      final result = await authRepository.sendPasswordResetEmail(
        email: 'invalid-email',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (err) => expect(err, 'Format email tidak valid.'),
        (_) => fail('Should not succeed'),
      );
    });

    test('maps too-many-requests to user friendly message', () async {
      fakeDataSource.firebaseAuthExceptionToThrow = FirebaseAuthException(
        code: 'too-many-requests',
      );

      final result = await authRepository.sendPasswordResetEmail(
        email: 'spam@example.com',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (err) => expect(
          err,
          'Terlalu banyak percobaan gagal. Silakan coba lagi nanti.',
        ),
        (_) => fail('Should not succeed'),
      );
    });

    test('maps network-request-failed to user friendly message', () async {
      fakeDataSource.firebaseAuthExceptionToThrow = FirebaseAuthException(
        code: 'network-request-failed',
      );

      final result = await authRepository.sendPasswordResetEmail(
        email: 'test@example.com',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (err) => expect(
          err,
          'Koneksi internet bermasalah. Periksa jaringan Anda.',
        ),
        (_) => fail('Should not succeed'),
      );
    });

    test('maps generic exception to string', () async {
      fakeDataSource.genericExceptionToThrow = Exception('Server timeout');

      final result = await authRepository.sendPasswordResetEmail(
        email: 'test@example.com',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (err) => expect(err, contains('Server timeout')),
        (_) => fail('Should not succeed'),
      );
    });
  });

  group('AuthRepositoryImpl Account Linking & Established Business Tests', () {
    late FakeAuthFirebaseDataSource fakeDataSource;
    late FakeUserFirebaseDataSource fakeUserDataSource;
    late AuthRepositoryImpl authRepository;

    setUp(() {
      fakeDataSource = FakeAuthFirebaseDataSource();
      fakeUserDataSource = FakeUserFirebaseDataSource();
      authRepository = AuthRepositoryImpl(
        dataSource: fakeDataSource,
        userDataSource: fakeUserDataSource,
      );
    });

    test(
      'links new UID to established business when previous login with same email exists',
      () async {
        // 1. Existing established account from Google login
        const establishedBusinessId = 'bis_google_123';
        fakeUserDataSource.usersByUid['google_uid'] = const UserModel(
          id: 'google_uid',
          email: 'ilham.kersa@gmail.com',
          name: 'Ilham Google',
          role: UserRole.owner,
          businessId: establishedBusinessId,
        );

        // 2. User logs in with Email/Password (getting email_uid)
        fakeDataSource.credentialToReturn = MockUserCredential(
          user: MockUser(
            uid: 'email_uid',
            email: 'ilham.kersa@gmail.com',
            displayName: 'Ilham Email',
          ),
        );

        final result = await authRepository.signInWithEmail(
          email: 'ilham.kersa@gmail.com',
          password: 'password123',
        );

        expect(result.isRight(), isTrue);
        final user = result.getOrElse(() => throw Exception());
        // Crucial: Must link to the established business, NOT create bis_email_uid
        expect(user.businessId, establishedBusinessId);
        expect(
          fakeUserDataSource.usersByUid['email_uid']?.businessId,
          establishedBusinessId,
        );
      },
    );

    test(
      'heals existing fallback profile bis_email_uid to established bis_google_123',
      () async {
        const establishedBusinessId = 'bis_google_123';
        // 1. Google owner profile
        fakeUserDataSource.usersByUid['google_uid'] = const UserModel(
          id: 'google_uid',
          email: 'ilham.kersa@gmail.com',
          name: 'Ilham Google',
          role: UserRole.owner,
          businessId: establishedBusinessId,
        );

        // 2. Existing fallback email profile that was accidentally created
        fakeUserDataSource.usersByUid['email_uid'] = const UserModel(
          id: 'email_uid',
          email: 'ilham.kersa@gmail.com',
          name: 'Ilham Email',
          role: UserRole.owner,
          businessId: 'bis_email_uid', // previous fallback!
        );

        fakeDataSource.credentialToReturn = MockUserCredential(
          user: MockUser(
            uid: 'email_uid',
            email: 'ilham.kersa@gmail.com',
          ),
        );

        final result = await authRepository.signInWithEmail(
          email: 'ilham.kersa@gmail.com',
          password: 'password123',
        );

        expect(result.isRight(), isTrue);
        final user = result.getOrElse(() => throw Exception());
        // Must heal and re-link to the established business!
        expect(user.businessId, establishedBusinessId);
        expect(
          fakeUserDataSource.usersByUid['email_uid']?.businessId,
          establishedBusinessId,
        );
      },
    );

    test(
      'creates fresh business if no other owner profile with same email exists',
      () async {
        fakeDataSource.credentialToReturn = MockUserCredential(
          user: MockUser(
            uid: 'fresh_uid',
            email: 'newowner@lacipos.id',
          ),
        );

        final result = await authRepository.signInWithEmail(
          email: 'newowner@lacipos.id',
          password: 'password123',
        );

        expect(result.isRight(), isTrue);
        final user = result.getOrElse(() => throw Exception());
        expect(user.businessId, 'bis_fresh_uid');
        expect(fakeUserDataSource.usersByUid['fresh_uid']?.businessId, 'bis_fresh_uid');
      },
    );
  });

  group('ForgotPasswordPage Widget & Logic Tests', () {
    testWidgets('renders request view with initial elements and empty email', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Lupa Kata Sandi?'), findsOneWidget);
      expect(
        find.text(
          'Masukkan email yang terdaftar di akun Anda. Kami akan mengirimkan tautan untuk mengatur ulang kata sandi.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('forgot_password_email_field')), findsOneWidget);
      expect(find.byKey(const ValueKey('send_reset_button')), findsOneWidget);
      expect(find.text('KIRIM TAUTAN RESET'), findsOneWidget);
      expect(find.text('Masuk'), findsOneWidget);
    });

    testWidgets('pre-fills initialEmail if provided', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(initialEmail: 'owner@example.com'),
      );
      await tester.pumpAndSettle();

      expect(find.text('owner@example.com'), findsOneWidget);
    });

    testWidgets('shows validation error when email is empty', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap submit with empty field
      await tester.tap(find.byKey(const ValueKey('send_reset_button')));
      await tester.pumpAndSettle();

      expect(find.text('Email wajib diisi'), findsOneWidget);
      expect(mockAuthRepository.resetCallCount, 0);
    });

    testWidgets('shows validation error when email format is invalid', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('forgot_password_email_field')),
        'invalidemailformat',
      );
      await tester.tap(find.byKey(const ValueKey('send_reset_button')));
      await tester.pumpAndSettle();

      expect(find.text('Format email tidak valid'), findsOneWidget);
      expect(mockAuthRepository.resetCallCount, 0);
    });

    testWidgets('transitions to success view when sendPasswordResetEmail succeeds', (tester) async {
      mockAuthRepository.resetResult = const Right(null);

      await tester.pumpWidget(
        buildTestWidget(initialEmail: 'user@lacipos.id'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('send_reset_button')));
      await tester.pump(); // Start async call
      await tester.pumpAndSettle(); // Finish animations

      expect(mockAuthRepository.resetCallCount, 1);
      expect(mockAuthRepository.lastRequestedEmail, 'user@lacipos.id');

      // Verify success screen contents
      expect(find.byKey(const ValueKey('success_view')), findsOneWidget);
      expect(find.text('Periksa Email Anda'), findsOneWidget);
      expect(find.text('user@lacipos.id'), findsOneWidget);
      expect(find.byKey(const ValueKey('open_email_app_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('resend_reset_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('back_to_login_button')), findsOneWidget);
      expect(find.textContaining('Kirim Ulang'), findsOneWidget);
    });

    testWidgets('stays on request view when sendPasswordResetEmail returns error', (tester) async {
      mockAuthRepository.resetResult = const Left('Akun dengan email ini tidak ditemukan.');

      await tester.pumpWidget(
        buildTestWidget(initialEmail: 'notfound@lacipos.id'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('send_reset_button')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(mockAuthRepository.resetCallCount, 1);
      // Still on request view
      expect(find.byKey(const ValueKey('request_view')), findsOneWidget);
      expect(find.text('Lupa Kata Sandi?'), findsOneWidget);
    });

    testWidgets('renders cleanly in dark mode without overflow', (tester) async {
      tester.view.physicalSize = const Size(360 * 2, 640 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.reset());

      await tester.pumpWidget(
        buildTestWidget(initialEmail: 'dark@lacipos.id', isDark: true),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lupa Kata Sandi?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
