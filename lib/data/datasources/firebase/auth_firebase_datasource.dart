import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

abstract class AuthFirebaseDataSource {
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  });

  Future<UserCredential> signInWithGoogle();

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
  Future<UserCredential> signInWithGoogle() async {
    log('masuk sign in with google');

    // 1. Authenticate (Identify the user)
    final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
    log('google user: ${googleUser.email}');

    // 2. Get Authentication data (for idToken)
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    // 3. Request Authorization (for accessToken)
    // We need at least email and profile scopes
    final auth = await googleUser.authorizationClient.authorizeScopes([
      'email',
      'profile',
    ]);

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await _firebaseAuth.signInWithCredential(credential);
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    return await _firebaseAuth.signOut();
  }

  @override
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
}
