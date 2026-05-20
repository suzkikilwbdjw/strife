import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:strife/data/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const AuthState()) {
    on<SignInRequested>(_onSignInRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<SignInWithYandexRequested>(_onSignInWithYandexRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<ResetPasswordRequested>(_onResetPasswordRequested);
  }

  Future<void> _onSignInRequested(
    SignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));

    try {
      await _authRepository.login(event.email, event.password);
      emit(state.copyWith(status: AuthStatus.success));
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Пользователь с такой почтой не найден.';
        case 'wrong-password':
          errorMessage = 'Неверный пароль. Попробуйте еще раз.';
        case 'invalid-credential':
          errorMessage = 'Неверная почта или пароль.';
        case 'user-disabled':
          errorMessage = 'Ваш аккаунт заблокирован.';
        case 'too-many-requests':
          errorMessage = 'Слишком много попыток. Попробуйте позже.';
        case 'network-request-failed':
          errorMessage = 'Проблемы с интернет-соединением.';
        default:
          errorMessage = 'Ошибка входа: ${e.message}';
      }
      emit(
        state.copyWith(status: AuthStatus.failure, errorMessage: errorMessage),
      );
    } catch (e) {
      emit(
        state.copyWith(status: AuthStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onSignUpRequested(
    SignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));

    try {
      final credential = await _authRepository.register(
        event.email,
        event.password,
      );
      final user = credential.user!;

      await user.updateDisplayName(event.displayName);

      final encodedName = Uri.encodeComponent(event.displayName);
      final avatarUrl =
          'https://seva.danilkin2244.fvds.ru/avatar/get-avatar?name=$encodedName&size=256&background=random&length=2&rounded=true&format=png';

      await user.updatePhotoURL(avatarUrl);
      await user.reload();

      final updatedUser = FirebaseAuth.instance.currentUser;
      if (updatedUser == null) {
        throw Exception('Пользователь не найден после регистрации');
      }

      await _authRepository.saveUserData(
        updatedUser,
        extraData: {'displayName': event.displayName, 'photoUrl': avatarUrl},
      );

      emit(state.copyWith(status: AuthStatus.success));
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'Эта почта уже занята другим пользователем.';
        case 'invalid-email':
          errorMessage = 'Некорректный формат электронной почты.';
        case 'weak-password':
          errorMessage = 'Пароль слишком простой. Придумайте что-то посложнее.';
        case 'network-request-failed':
          errorMessage = 'Проблемы с интернет-соединением.';
        default:
          errorMessage = 'Ошибка авторизации: ${e.message}';
      }
      emit(
        state.copyWith(status: AuthStatus.failure, errorMessage: errorMessage),
      );
    } catch (e) {
      emit(
        state.copyWith(status: AuthStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onSignInWithYandexRequested(
    SignInWithYandexRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));

    try {
      final credential = await _authRepository.loginWithYandex();

      if (credential == null) {
        throw Exception('Yandex login failed');
      }

      final user = credential.user!;
      await _authRepository.saveUserData(user);

      emit(state.copyWith(status: AuthStatus.success));
    } catch (e) {
      emit(
        state.copyWith(status: AuthStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));

    try {
      await _authRepository.logout();
      emit(state.copyWith(status: AuthStatus.success));
    } catch (e) {
      emit(
        state.copyWith(status: AuthStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onResetPasswordRequested(
    ResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));

    try {
      await _authRepository.sendPasswordResetEmail(event.email);
      emit(
        state.copyWith(
          status: AuthStatus.success,
          successMessage: 'Письмо для сброса пароля отправлено на вашу почту',
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'network-request-failed':
          errorMessage = 'Проблемы с интернет-соединением.';
        default:
          errorMessage = 'Ошибка сброса пароля: ${e.message}';
      }
      emit(
        state.copyWith(status: AuthStatus.failure, errorMessage: errorMessage),
      );
    } catch (e) {
      emit(
        state.copyWith(status: AuthStatus.failure, errorMessage: e.toString()),
      );
    }
  }
}
