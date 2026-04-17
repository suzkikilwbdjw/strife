import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:strife/data/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  // ignore: unused_field
  bool _isLoading = false;
  String? _error;

  String? get error => _error;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Логика входа
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _error = null;
    try {
      await _authRepository.login(email, password);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signInYandex() async {
    _setLoading(true);
    _error = null;
    try {
      final credential = await _authRepository.loginWithYandex();

      if (credential == null) {
        throw Exception('Yandex login failed');
      }

      final user = credential.user!;

      await _authRepository.saveUserData(user);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Логика регистрации
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String secondName,
    required DateTime dob,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      final credential = await _authRepository.register(email, password);

      final user = credential.user!;

      await user.updateDisplayName('$name $secondName');
      await user.updatePhotoURL(
        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRL5SN9kRO7M2hLQYFw-dNivpt11E-XLyIYcw&s',
      );
      await user.reload();

      final updatedUser = FirebaseAuth.instance.currentUser!;

      await _authRepository.saveUserData(
        updatedUser,
        extraData: {
          'name': name,
          'secondName': secondName,
          'dateOfBirth': dob.toIso8601String(),
        },
      );

      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          _error = 'Эта почта уже занята другим пользователем.';
        case 'invalid-email':
          _error = 'Некорректный формат электронной почты.';
        case 'weak-password':
          _error = 'Пароль слишком простой. Придумайте что-то посложнее.';
        case 'network-request-failed':
          _error = 'Проблемы с интернет-соединением.';
        default:
          _error = 'Ошибка авторизации: ${e.message}';
      }
      _setLoading(false);
      return false;
    }
  }
}
