import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthenticationModel extends ChangeNotifier {
  String? _email;
  String? _password;
  String? _error;
  bool _isAuth = false;

  // Гетеры
  String? get password => _password;
  Object? get error => _error;
  bool get isAuth => _isAuth;
  String? get email => _email;

  // Сеттеры
  void setPassword(String? password) {
    _password = password;
  }

  void setEmail(String? email) {
    _email = email;
  }

  Future<void> signInWithEmailAndPassword() async {
    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: _email!, password: _password!);
      _isAuth = userCredential.user != null;
    } on FirebaseAuthException catch (e) {
      _error = e.toString();
      _isAuth = false;
    }
  }

  Future<void> signWithGoole() async {
    try {
      // Инициализация
      final GoogleSignIn signIn = GoogleSignIn.instance;
      signIn.initialize(
        serverClientId: '122925758220-me6bo5imb8o9v1612eteq474rfjatg9k',
      );

      final GoogleSignInAccount googleSignInAccount = await signIn
          .authenticate();

      final googleSignInAuthentication = googleSignInAccount.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleSignInAuthentication.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      await _writeToDB(FirebaseAuth.instance.currentUser!);

      _isAuth = true;
      _error = null;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        _error = null;
      } else {
        _error = e.description;
      }
      _isAuth = false;
    } catch (e) {
      _error = e.toString();
      _isAuth = false;
    }
  }

  Future<void> _writeToDB(User user) async {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'displayName': user.displayName,
      'photoUrl': user.photoURL,
      'email': user.email,
      'uid': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
