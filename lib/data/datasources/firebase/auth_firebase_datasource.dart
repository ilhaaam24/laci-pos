import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

abstract class AuthFirebaseDataSource {
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  });

  Future<UserCredential> signInWithGoogle();

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  });

  Future<void> signOut();

  User? getCurrentUser();

  Stream<User?> get authStateChanges;
}

class AuthFirebaseDataSourceImpl implements AuthFirebaseDataSource {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AuthFirebaseDataSourceImpl({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  @override
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<UserCredential> signInWithGoogle() async {
    try {
      log('Starting Google Sign-In flow...');

      // 1. Trigger Google Sign-In account picker
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      log('Google user authenticated: ${googleUser.email}');

      // 2. Get authentication tokens
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      if (googleAuth.idToken == null) {
        log('ID Token is null. Authentication failed.');
        throw FirebaseAuthException(
          code: 'ERROR_MISSING_ID_TOKEN',
          message: 'Gagal mendapatkan ID Token dari Google',
        );
      }

      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      log('Signing into Firebase with Google credentials...');
      return await _firebaseAuth.signInWithCredential(credential);
    } catch (e, stackTrace) {
      log('Error during Google Sign-In: $e');
      log('Stack trace: $stackTrace');

      if (e is FirebaseAuthException) {
        rethrow;
      }

      if (e is GoogleSignInException && e.code == GoogleSignInExceptionCode.canceled) {
        throw FirebaseAuthException(
          code: 'ERROR_ABORTED_BY_USER',
          message: 'Proses login Google dibatalkan oleh pengguna',
        );
      }

      throw FirebaseAuthException(
        code: 'ERROR_GOOGLE_SIGN_IN',
        message: 'Gagal login dengan Google: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      log('Error signing out from Google: $e');
    }
    return await _firebaseAuth.signOut();
  }

  @override
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
}
