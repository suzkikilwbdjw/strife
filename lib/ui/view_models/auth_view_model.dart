import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:strife/data/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  bool _isLoading = false;
  String? _error;

  String? get error => _error;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
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
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          _error = 'Пользователь с такой почтой не найден.';
        case 'wrong-password':
          _error = 'Неверный пароль. Попробуйте еще раз.';
        case 'invalid-credential':
          _error = 'Неверная почта или пароль.';
        case 'user-disabled':
          _error = ' Ваш аккаунт заблокирован.';
        case 'too-many-requests':
          _error = 'Слишком много попыток. Попробуйте позже.';
        default:
          _error = 'Ошибка входа: ${e.message}';
      }
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
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  // Логика регистрации
  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      final credential = await _authRepository.register(email, password);

      final user = credential.user!;

      // Обновление отображаемого имени пользователя
      await user.updateDisplayName(displayName);

      // Используем fullName для URL
      final encodedName = Uri.encodeComponent(displayName);
      final avatarUrl =
          'http://62.109.2.27:4000/avatar/get-avatar?name=$encodedName&size=256&background=random&length=2&rounded=true&format=png';

      // Обновление аватарки пользователя
      await user.updatePhotoURL(avatarUrl);

      // Принудительно обновляем локального пользователя
      await user.reload();

      // Используем текущего пользователя
      final updatedUser = FirebaseAuth.instance.currentUser;
      if (updatedUser == null) {
        throw Exception('Пользователь не найден после регистрации');
      }

      await _authRepository.saveUserData(
        updatedUser,
        extraData: {'displayName': displayName},
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

  // Логика выходa
  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _authRepository.logout();
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
    }
  }
}
