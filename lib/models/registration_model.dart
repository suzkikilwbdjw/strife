import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class RegistrationModel extends ChangeNotifier {
  // Атрибуты
  String? _email;
  String? _name;
  String? _secondName;
  late String _displayName;
  String? _password;
  String? _error;
  String? _photoUrl;
  PhoneAuthCredential? _phoneNumber;
  DateTime? _dateOfBirth;
  bool _isRegister = false;

  // Геттеры
  String? get email => _email;
  String? get displayName => _displayName;
  String? get password => _password;
  String? get error => _error;
  String? get photoUrl => _photoUrl;
  String? get name => _name;
  String? get secondName => _secondName;
  bool get isRegister => _isRegister;

  Map<String, dynamic> get data => {
    'displayName': _displayName,
    'email': _email,
  };

  void setEmail(String? email) {
    _email = email;
  }

  void setPassword(String? password) {
    _password = password;
  }

  void setDateOfBirth(DateTime dateOfBirth) {
    _dateOfBirth = dateOfBirth;
  }

  void setPhoneNumber(PhoneAuthCredential phoneNumber) {
    _phoneNumber = phoneNumber;
  }

  Future<void> registerWithEmailAndPassword() async {
    try {
      // Создание пользователя с помощью электронной почты и пароля
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: _email!, password: _password!);

      // Обновление пользователя
      await _defaultSetUpInfoUser(userCredential);

      // Запись о пользователе в БД
      await _writeToDB(FirebaseAuth.instance.currentUser!);

      _isRegister = true;
      _error = null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        _error = 'Пароль слишком слабый';
      } else if (e.code == 'email-already-in-use') {
        _error = 'Аккаунт с данной почтой уже существует';
      }
      _error = e.toString();
      _isRegister = false;
    } catch (e) {
      _error = e.toString();
      _isRegister = false;
    } finally {
      notifyListeners();
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

      _isRegister = true;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        _error = null;
      } else {
        _error = e.description;
      }
      _isRegister = false;
    } catch (e) {
      _error = e.toString();
      _isRegister = false;
    }
  }

  Future<void> _writeToDB(User user) async {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'name': _name,
      'secondName': _secondName,
      'dateOfBirth': _dateOfBirth,
      'displayName': user.displayName,
      'photoUrl': user.photoURL,
      'email': user.email,
      'uid': user.uid,
      'phoneNumber': user.phoneNumber,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _defaultSetUpInfoUser(UserCredential userCredential) async {
    _displayName = '$_name $_secondName';
    // Обновление отображаемого имени пользователя
    await userCredential.user!.updateDisplayName(_displayName);

    // Обновление фото пользователя
    await userCredential.user!.updatePhotoURL(
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSeYnkXnb1ypzbGzYabcpPt7hWLDHUktc_BIQ&s',
    );

    // Обновление номера телефона
    await userCredential.user!.updatePhoneNumber(_phoneNumber!);

    await userCredential.user!.reload();
  }
}
