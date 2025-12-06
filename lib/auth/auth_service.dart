import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Listen to auth changes
  Stream<User?> get user => _firebaseAuth.authStateChanges();

  // EMAIL + PASSWORD SIGN-IN
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
      notifyListeners();
      return result.user;
    } catch (e) {
      debugPrint("Email Sign-In Error: $e");
      return null;
    }
  }

  // EMAIL + PASSWORD SIGN-UP
  Future<User?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);
      notifyListeners();
      return result.user;
    } catch (e) {
      debugPrint("Email Sign-Up Error: $e");
      return null;
    }
  }

  // GOOGLE SIGN-IN
  Future<User?> signInWithGoogle() async {
    try {
      // Correct way in google_sign_in:7.2.0
      final GoogleSignIn googleSignIn = GoogleSignIn.standard(
        scopes: ['email'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser
          .authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      UserCredential result = await _firebaseAuth.signInWithCredential(
          credential);
      notifyListeners();
      return result.user;
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      return null;
    }
  }

  // PASSWORD RESET
  Future<void> sendPasswordReset(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint("Password Reset Error: $e");
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    try {
      // Must also use standard()
      await GoogleSignIn.standard().signOut();
    } catch (e) {
      debugPrint("Google Sign-Out Error: $e");
    }
    notifyListeners();
  }
}






