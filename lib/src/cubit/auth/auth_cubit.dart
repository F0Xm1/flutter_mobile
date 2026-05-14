import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_auth;
import 'package:test1/core/supabase_client.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  late final StreamSubscription<supabase_auth.AuthState> _authStateSubscription;

  AuthCubit() : super(_initialState()) {
    _authStateSubscription = supabase.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;

      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    });
  }

  static AuthState _initialState() {
    final user = supabase.auth.currentUser;
    return user == null ? AuthUnauthenticated() : AuthAuthenticated(user);
  }

  Future<void> signIn(String email, String password) async {
    emit(AuthLoading());
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;

      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    } on supabase_auth.AuthException catch (error) {
      emit(AuthError(_mapAuthException(error)));
    } catch (_) {
      emit(AuthError('Не вдалося увійти. Спробуйте ще раз.'));
    }
  }

  Future<void> signUp(String email, String password) async {
    emit(AuthLoading());
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );
      final user = response.user;

      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    } on supabase_auth.AuthException catch (error) {
      emit(AuthError(_mapAuthException(error)));
    } catch (_) {
      emit(AuthError('Не вдалося зареєструватися. Спробуйте ще раз.'));
    }
  }

  Future<void> signOut() async {
    emit(AuthLoading());
    try {
      await supabase.auth.signOut();
      emit(AuthUnauthenticated());
    } on supabase_auth.AuthException catch (error) {
      emit(AuthError(_mapAuthException(error)));
    } catch (_) {
      emit(AuthError('Не вдалося вийти з акаунта. Спробуйте ще раз.'));
    }
  }

  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    try {
      await supabase.auth.signInWithOAuth(
        supabase_auth.OAuthProvider.google,
      );
    } on supabase_auth.AuthException catch (error) {
      emit(AuthError(_mapAuthException(error)));
    } catch (_) {
      emit(AuthError('Не вдалося увійти через Google. Спробуйте ще раз.'));
    }
  }

  Future<void> login(String email, String password) => signIn(email, password);

  Future<void> logout() => signOut();

  String _mapAuthException(supabase_auth.AuthException error) {
    final message = error.message.toLowerCase();

    if (message.contains('invalid login credentials')) {
      return 'Невірний email або пароль.';
    }
    if (message.contains('email not confirmed')) {
      return 'Підтвердіть email перед входом.';
    }
    if (message.contains('user already registered') ||
        message.contains('already registered')) {
      return 'Користувач з таким email вже зареєстрований.';
    }
    if (message.contains('password')) {
      return 'Пароль не відповідає вимогам безпеки.';
    }
    if (message.contains('email')) {
      return 'Перевірте правильність email.';
    }

    return 'Помилка автентифікації. Спробуйте ще раз.';
  }

  @override
  Future<void> close() async {
    await _authStateSubscription.cancel();
    return super.close();
  }
}
